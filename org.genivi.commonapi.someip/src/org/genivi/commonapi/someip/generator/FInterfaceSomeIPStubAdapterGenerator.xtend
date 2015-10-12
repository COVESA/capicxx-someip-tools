/* Copyright (C) 2014, 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import java.util.HashMap
import java.util.List
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModelElement
import org.franca.deploymodel.core.FDeployedProvider
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.genivi.commonapi.core.generator.FTypeGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.franca.core.franca.FArgument

class FInterfaceSomeIPStubAdapterGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaSomeIPGeneratorExtensions
    @Inject private extension FrancaSomeIPDeploymentAccessorHelper

    def generateStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess, PropertyAccessor deploymentAccessor, List<FDProvider> providers, IResource modelid) {
        fileSystemAccess.generateFile(fInterface.someipStubAdapterHeaderPath, PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, fInterface.generateStubAdapterHeader(deploymentAccessor, modelid))
        fileSystemAccess.generateFile(fInterface.someipStubAdapterSourcePath, PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, fInterface.generateStubAdapterSource(deploymentAccessor, providers, modelid))
    }

    def private generateStubAdapterHeader(FInterface _interface, PropertyAccessor _accessor, IResource _modelid) '''
        «generateCommonApiLicenseHeader(_interface, _modelid)»
        «FTypeGenerator::generateComments(_interface, false)»
        #ifndef «_interface.defineName.toUpperCase»_SOMEIP_STUB_ADAPTER_HPP_
        #define «_interface.defineName.toUpperCase»_SOMEIP_STUB_ADAPTER_HPP_

        #include <«_interface.stubHeaderPath»>
        «IF _interface.base != null»
        #include <«_interface.base.someipStubAdapterHeaderPath»>
        «ENDIF»
        «val DeploymentHeaders = _interface.getDeploymentInputIncludes(_accessor)»
        «DeploymentHeaders.map["#include <" + it + ">"].join("\n")»        

        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif

        #include <CommonAPI/SomeIP/StubAdapterHelper.hpp>
        #include <CommonAPI/SomeIP/StubAdapter.hpp>
        #include <CommonAPI/SomeIP/Factory.hpp>
        #include <CommonAPI/SomeIP/Types.hpp>
        #include <CommonAPI/SomeIP/Config.hpp>

        #undef COMMONAPI_INTERNAL_COMPILATION

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»

        typedef CommonAPI::SomeIP::StubAdapterHelper<«_interface.stubClassName»> «_interface.someipStubAdapterHelperClassName»;

        class «_interface.someipStubAdapterClassNameInternal»
            : public virtual «_interface.stubAdapterClassName»,
              public «_interface.someipStubAdapterHelperClassName»«IF _interface.base != null»,
              public «_interface.base.getTypeCollectionName(_interface)»SomeIPStubAdapterInternal«ENDIF»
        {
        public:
            «_interface.someipStubAdapterClassNameInternal»(
                    const CommonAPI::SomeIP::Address &_address,
                    const std::shared_ptr<CommonAPI::SomeIP::ProxyConnection> &_connection,
                    const std::shared_ptr<CommonAPI::StubBase> &_stub);

            ~«_interface.someipStubAdapterClassNameInternal»();

            «FOR attribute : _interface.attributes»
                «IF attribute.isObservable»
                    «FTypeGenerator::generateComments(attribute, false)»
                    void «attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(_interface, true)»& value);
                «ENDIF»
            «ENDFOR»

            «FOR broadcast: _interface.broadcasts»
                «FTypeGenerator::generateComments(broadcast, false)»
                «IF broadcast.selective»
                    void «broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, _interface)»);
                    void «broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, _interface, true)»);
                    void «broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success);
                    void «broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId);
                    std::shared_ptr<CommonAPI::ClientIdList> const «broadcast.stubAdapterClassSubscribersMethodName»();
                «ELSE»
                    void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(_interface, true) + '& ' + elementName].join(', ')»);
                «ENDIF»
            «ENDFOR»

            «FOR managed: _interface.managedInterfaces»
                «managed.stubRegisterManagedMethod»;
                bool «managed.stubDeregisterManagedName»(const std::string&);
                std::set<std::string>& «managed.stubManagedSetGetterName»();
            «ENDFOR»

            const «_interface.someipStubAdapterHelperClassName»::StubDispatcherTable& getStubDispatcherTable();
            const CommonAPI::SomeIP::StubAttributeTable& getStubAttributeTable();

            void deactivateManagedInstances();

        «IF _interface.base != null»
            virtual void init(std::shared_ptr<CommonAPI::SomeIP::StubAdapter> instance) {
                return «_interface.someipStubAdapterHelperClassName»::init(instance);
            }

            virtual void deinit() {
                return «_interface.someipStubAdapterHelperClassName»::deinit();
            }

            virtual bool onInterfaceMessage(const CommonAPI::SomeIP::Message &_message) {
                return «_interface.someipStubAdapterHelperClassName»::onInterfaceMessage(_message);
            }
        «ENDIF»

        static CommonAPI::SomeIP::GetAttributeStubDispatcher<
                «_interface.stubFullClassName»,
                CommonAPI::Version
                > get«_interface.elementName»InterfaceVersionStubDispatcher;

        «generateAttributeDispatcherDeclarations(_interface, _accessor)»

        «IF _interface.base != null»
            #ifdef WIN32
            «generateAttributeDispatcherDeclarations(_interface.base, _accessor)»
            #endif
        «ENDIF»

        «var counterMap = new HashMap<String, Integer>()»
        «var methodNumberMap = new HashMap<FMethod, Integer>()»
        «_interface.generateMethodDispatcherDeclarations(_interface, counterMap, methodNumberMap)»

        «IF _interface.base != null»
            #ifdef WIN32
            «_interface.base.recursivelyGenerateMethodDispatcherDeclarations(_interface, counterMap, methodNumberMap)»
            #endif
        «ENDIF»

         private:
            «FOR eventGroup : _interface.getSelectiveEventGroups(_accessor)»
                bool selectiveEventSubscribeHandler_«eventGroup»(CommonAPI::SomeIP::client_id_t _client, bool subscribe);
            «ENDFOR»
            «FOR broadcast: _interface.broadcasts»
                «IF broadcast.selective»
                    std::mutex «broadcast.className»Mutex_;
                «ENDIF»
            «ENDFOR»
            «FOR managed: _interface.managedInterfaces»
                std::set<std::string> «managed.stubManagedSetName»;
            «ENDFOR»
            «_interface.someipStubAdapterHelperClassName»::StubDispatcherTable stubDispatcherTable_;
            CommonAPI::SomeIP::StubAttributeTable stubAttributeTable_;
        };

        class «_interface.someipStubAdapterClassName»
            : public «_interface.someipStubAdapterClassNameInternal»,
              public std::enable_shared_from_this<«_interface.someipStubAdapterClassName»> {
        public:
            «_interface.someipStubAdapterClassName»(const CommonAPI::SomeIP::Address &_address,
                                                    const std::shared_ptr<CommonAPI::SomeIP::ProxyConnection> &_connection,
                                                    const std::shared_ptr<CommonAPI::StubBase> &_stub) 
                : CommonAPI::SomeIP::StubAdapter(_address, _connection),
                  «_interface.someipStubAdapterClassNameInternal»(_address, _connection, _stub) {
            }
        };

        «_interface.model.generateNamespaceEndDeclaration»
        «_interface.generateVersionNamespaceEnd»

        #endif // «_interface.defineName»_SOMEIP_STUB_ADAPTER_HPP_
    '''

    def private String generateAttributeDispatcherDeclarations(FInterface _interface, PropertyAccessor _accessor) '''
        «FOR a : _interface.attributes»
            «val typeName = a.getTypeName(_interface, true)»
            «FTypeGenerator::generateComments(a, false)»
            «val String deploymentType = a.getDeploymentType(_interface, true)»
            «val String getIdentifier = a.getGetterIdentifier(_accessor)» 
            «IF getIdentifier != "0x0"»
            static CommonAPI::SomeIP::GetAttributeStubDispatcher<
	                «_interface.stubFullClassName»,
	                «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
	                «deploymentType»«ENDIF»
            > «a.someipGetStubDispatcherVariable»;
            «ENDIF»
            «IF !a.isReadonly»
                static CommonAPI::SomeIP::Set«IF a.observable»Observable«ENDIF»AttributeStubDispatcher<
                    «_interface.stubFullClassName»,
                    «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                    «deploymentType»«ENDIF»
                > «a.someipSetStubDispatcherVariable»;
            «ENDIF»
        «ENDFOR»
        «IF _interface.base != null»
            «_interface.base.generateAttributeDispatcherDeclarations(_accessor)»
        «ENDIF»
    '''

    def private String generateMethodDispatcherDeclarations(FInterface _interface,
                                                            FInterface _container,
                                                            HashMap<String, Integer> _counters, 
                                                            HashMap<FMethod, Integer> _methods) '''
        «val accessor = getAccessor(_interface)»                           
        «FOR method : _interface.methods»              
            «FTypeGenerator::generateComments(method, false)»
            «IF !method.isFireAndForget»
                static CommonAPI::SomeIP::MethodWithReplyStubDispatcher<
                    «_interface.stubFullClassName»,
                    std::tuple<«method.allInTypes»>,
                    std::tuple<«method.allOutTypes»>,
                    std::tuple<«method.inArgs.getDeploymentTypes(_interface, accessor)»>,
                    std::tuple<«method.getErrorDeploymentType(true)»«method.outArgs.getDeploymentTypes(_interface, accessor)»>
                    «IF !(_counters.containsKey(method.someipStubDispatcherVariable))»
                        «{_counters.put(method.someipStubDispatcherVariable, 0);  _methods.put(method, 0);""}»
                > «method.someipStubDispatcherVariable»;
                «ELSE»
                    «{_counters.put(method.someipStubDispatcherVariable, _counters.get(method.someipStubDispatcherVariable) + 1);  _methods.put(method, _counters.get(method.someipStubDispatcherVariable));""}»
                > «method.someipStubDispatcherVariable»«Integer::toString(_counters.get(method.someipStubDispatcherVariable))»;
                «ENDIF»
            «ELSE»
                static CommonAPI::SomeIP::MethodStubDispatcher<
                    «_interface.stubFullClassName»,
                    std::tuple<«method.allInTypes»>,
                    std::tuple<«method.inArgs.getDeploymentTypes(_interface, accessor)»>
                    «IF !(_counters.containsKey(method.someipStubDispatcherVariable))»
                        «{_counters.put(method.someipStubDispatcherVariable, 0); _methods.put(method, 0);""}»
                > «method.someipStubDispatcherVariable»;
                «ELSE»
                    «{_counters.put(method.someipStubDispatcherVariable, _counters.get(method.someipStubDispatcherVariable) + 1);  _methods.put(method, _counters.get(method.someipStubDispatcherVariable));""}»
                > «method.someipStubDispatcherVariable»«Integer::toString(_counters.get(method.someipStubDispatcherVariable))»;
                «ENDIF»
            «ENDIF»
        «ENDFOR»
    '''
    
    def private String recursivelyGenerateMethodDispatcherDeclarations(FInterface _interface, 
                                                                       FInterface _container,
                                                                       HashMap<String, Integer> _counters, 
                                                                       HashMap<FMethod, Integer> _methods) '''
        «_interface.generateMethodDispatcherDeclarations(_container, _counters, _methods)»
        «IF _interface.base != null»
            «_interface.base.recursivelyGenerateMethodDispatcherDeclarations(_container, _counters, _methods)»
        «ENDIF»
    '''

    def private generateAttributeDispatcherDefinitions(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) '''
            «FTypeGenerator::generateComments(_attribute, false)»
            «val typeName = _attribute.getTypeName(_interface, true)»
            «val String deploymentType = _attribute.getDeploymentType(_interface, true)»
            «val String getIdentifier = _attribute.getGetterIdentifier(_accessor)» 
            «IF getIdentifier != "0x0"»
            CommonAPI::SomeIP::GetAttributeStubDispatcher<
	                    «_interface.stubFullClassName»,
	                    «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
	                    «deploymentType»«ENDIF»
            > «_interface.someipStubAdapterClassNameInternal»::«_attribute.someipGetStubDispatcherVariable»(
            &«_interface.stubClassName»::«_attribute.stubClassGetMethodName»«IF _accessor.hasDeployment(_attribute)», «_attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor)»«ENDIF»);
            «ENDIF»
            «IF !_attribute.isReadonly»
                CommonAPI::SomeIP::Set«IF _attribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                        «_interface.stubFullClassName»,
                        «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                        «deploymentType»«ENDIF»
                        > «_interface.someipStubAdapterClassNameInternal»::«_attribute.someipSetStubDispatcherVariable»(
                                &«_interface.stubClassName»::«_attribute.stubClassGetMethodName»,
                                &«_interface.stubRemoteEventClassName»::«_attribute.stubRemoteEventClassSetMethodName»,
                                &«_interface.stubRemoteEventClassName»::«_attribute.stubRemoteEventClassChangedMethodName»«IF _attribute.observable»,
                                &«_interface.stubAdapterClassName»::«_attribute.stubAdapterClassFireChangedMethodName»«ENDIF»«IF _accessor.hasDeployment(_attribute)»,
                                «_attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor)»«ENDIF»
                          );
            «ENDIF»
    '''

    def private generateMethodDispatcherDefinitions(FMethod _method, FInterface _interface, FInterface _thisInterface, 
                                                    PropertyAccessor _accessor,
                                                    HashMap<String, Integer> counterMap, 
                                                    HashMap<FMethod, Integer> methodnumberMap) '''
        «FTypeGenerator::generateComments(_method, false)»
        «IF !_method.isFireAndForget»
            CommonAPI::SomeIP::MethodWithReplyStubDispatcher<
                «_interface.stubFullClassName»,
                std::tuple<«_method.allInTypes»>,
                std::tuple<«_method.allOutTypes»>,
                std::tuple<«_method.inArgs.getDeploymentTypes(_interface, _accessor)»>,
                std::tuple<«_method.getErrorDeploymentType(true)»«_method.outArgs.getDeploymentTypes(_interface, _accessor)»>                
            «IF !(counterMap.containsKey(_method.someipStubDispatcherVariable))»
                «{counterMap.put(_method.someipStubDispatcherVariable, 0);  methodnumberMap.put(_method, 0);""}»
            > «_thisInterface.someipStubAdapterClassNameInternal»::«_method.someipStubDispatcherVariable»(
                &«_interface.stubClassName + "::" + _method.elementName», 
                «_method.getDeployments(_interface, _accessor, true, false)»,
                «_method.getDeployments(_interface, _accessor, false, true)»);
            «ELSE»
                «{counterMap.put(_method.someipStubDispatcherVariable, counterMap.get(_method.someipStubDispatcherVariable) + 1);  methodnumberMap.put(_method, counterMap.get(_method.someipStubDispatcherVariable));""}»
            > «_interface.someipStubAdapterClassNameInternal»::«_method.someipStubDispatcherVariable»«Integer::toString(counterMap.get(_method.someipStubDispatcherVariable))»(
                &«_interface.stubClassName + "::" + _method.elementName», 
                «_method.getDeployments(_interface, _accessor, true, false)»,
                «_method.getDeployments(_interface, _accessor, false, true)»);
            «ENDIF»
        «ELSE»
            CommonAPI::SomeIP::MethodStubDispatcher<
                «_interface.stubFullClassName»,
                std::tuple<«_method.allInTypes»>,
                std::tuple<«_method.inArgs.getDeploymentTypes(_interface, _accessor)»>
            «IF !(counterMap.containsKey(_method.someipStubDispatcherVariable))»
                «{counterMap.put(_method.someipStubDispatcherVariable, 0); methodnumberMap.put(_method, 0);""}»
            > «_thisInterface.someipStubAdapterClassNameInternal»::«_method.someipStubDispatcherVariable»(
                &«_interface.stubClassName + "::" + _method.elementName»,
                «_method.getDeployments(_interface, _accessor, true, false)»);
            «ELSE»
                «{counterMap.put(_method.someipStubDispatcherVariable, counterMap.get(_method.someipStubDispatcherVariable) + 1);  methodnumberMap.put(_method, counterMap.get(_method.someipStubDispatcherVariable));""}»
            > «_interface.someipStubAdapterClassNameInternal»::«_method.someipStubDispatcherVariable»«Integer::toString(counterMap.get(_method.someipStubDispatcherVariable))»(
                &«_interface.stubClassName + "::" + _method.elementName», 
                «_method.getDeployments(_interface, _accessor, true, false)»);
            «ENDIF»
        «ENDIF»
    '''

    def private generateBroadcastDispatcherDefinitions(FBroadcast fBroadcast, FInterface fInterface) '''
        CommonAPI::SomeIP::MethodWithReplyAdapterDispatcher<
            «fInterface.stubClassName»,
            «fInterface.stubAdapterClassName»,
            std::tuple<>,
            std::tuple<bool>
            > «fInterface.someipStubAdapterClassNameInternal»::«fBroadcast.dbusStubDispatcherVariableSubscribe»(&«fInterface.stubAdapterClassName + "::" + fBroadcast.subscribeSelectiveMethodName», "b");

        CommonAPI::SomeIP::MethodWithReplyAdapterDispatcher<
            «fInterface.stubClassName»,
            «fInterface.stubAdapterClassName»,
            std::tuple<>,
            std::tuple<>
            > «fInterface.someipStubAdapterClassNameInternal»::«fBroadcast.dbusStubDispatcherVariableUnsubscribe»(&«fInterface.stubAdapterClassName + "::" + fBroadcast.unsubscribeSelectiveMethodName», "");
    '''

   def private getDeployedTypeName(FArgument _arg, FInterface _interface)'''
            «val String deploymentType = _arg.getDeploymentType(_interface, true)»
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""» CommonAPI::Deployable< «_arg.getTypeName(_interface, true)», «deploymentType» > «ELSE» «_arg.getTypeName(_interface, true)»«ENDIF»
   '''

   def private  getDeployedElementName(FArgument _arg, FInterface _interface)'''
   «val String deploymentType = _arg.getDeploymentType(_interface, true)»
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""» deployed_«_arg.name» «ELSE»_«_arg.name»«ENDIF»
   '''

    def private generateStubAdapterSource(FInterface _interface, PropertyAccessor _accessor, List<FDProvider> providers, IResource _modelid) '''
        «generateCommonApiLicenseHeader(_interface, _modelid)»
        #include <«_interface.someipStubAdapterHeaderPath»>
        #include <«_interface.headerPath»>
        
        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif

        #include <CommonAPI/SomeIP/AddressTranslator.hpp>
        
        #undef COMMONAPI_INTERNAL_COMPILATION

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»

        std::shared_ptr<CommonAPI::SomeIP::StubAdapter> create«_interface.someipStubAdapterClassName»(
                           const CommonAPI::SomeIP::Address &_address,
                           const std::shared_ptr<CommonAPI::SomeIP::ProxyConnection> &_connection,
                           const std::shared_ptr<CommonAPI::StubBase> &_stub) {
            return std::make_shared<«_interface.someipStubAdapterClassName»>(_address, _connection, _stub);
        }

        INITIALIZER(register«_interface.someipStubAdapterClassName») {
            «FOR p : providers»
                «val PropertyAccessor providerAccessor = new PropertyAccessor(new FDeployedProvider(p))»
                «FOR i : p.instances.filter[target == _interface]»
                    CommonAPI::SomeIP::AddressTranslator::get()->insert(
                        "local:«_interface.fullyQualifiedName»:«providerAccessor.getInstanceId(i)»",
                        0x«Integer.toHexString(_accessor.getSomeIpServiceID(_interface))», 0x«Integer.toHexString(providerAccessor.getSomeIpInstanceID(i))»);
                «ENDFOR»
            «ENDFOR»
            CommonAPI::SomeIP::Factory::get()->registerStubAdapterCreateMethod(
                «_interface.elementName»::getInterface(), 
                &create«_interface.someipStubAdapterClassName»);
        }

        «_interface.someipStubAdapterClassNameInternal»::~«_interface.someipStubAdapterClassNameInternal»() {
            «FOR eventGroup : _interface.getSelectiveEventGroups(_accessor)»
                connection_->unregisterSubsciptionHandler(getSomeIpAddress(), «eventGroup»);
            «ENDFOR»
            deactivateManagedInstances();
            «_interface.someipStubAdapterHelperClassName»::deinit();
        }

        void «_interface.someipStubAdapterClassNameInternal»::deactivateManagedInstances() {
            «IF !_interface.managedInterfaces.empty»
                std::set<std::string>::iterator iter;
                std::set<std::string>::iterator iterNext;
            «ENDIF»

            «FOR managed : _interface.managedInterfaces»
                iter = «managed.stubManagedSetName».begin();
                while (iter != «managed.stubManagedSetName».end()) {
                    iterNext = std::next(iter);

                    if («managed.stubDeregisterManagedName»(*iter)) {
                        iter = iterNext;
                    }
                    else {
                        iter++;
                    }
                }
            «ENDFOR»
        }

        CommonAPI::SomeIP::GetAttributeStubDispatcher<
                «_interface.stubFullClassName»,
                CommonAPI::Version
                > «_interface.someipStubAdapterClassNameInternal»::get«_interface.elementName»InterfaceVersionStubDispatcher(&«_interface.stubClassName»::getInterfaceVersion);

        «FOR attribute : _interface.attributes»
            «generateAttributeDispatcherDefinitions(attribute, _interface, _accessor)»
        «ENDFOR»

        «IF _interface.base != null»
            #ifdef WIN32
            «FOR attribute : _interface.inheritedAttributes»
                «generateAttributeDispatcherDefinitions(attribute, _interface, _accessor)»
            «ENDFOR»
            #endif
        «ENDIF»

        «var counterMap = new HashMap<String, Integer>()»
        «var methodNumberMap = new HashMap<FMethod, Integer>()»
        «FOR method : _interface.methods»
            «generateMethodDispatcherDefinitions(method, _interface, _interface, _accessor, counterMap, methodNumberMap)»
        «ENDFOR»

        «IF _interface.base != null»
            #ifdef WIN32
            «FOR method : _interface.inheritedMethods»
                «generateMethodDispatcherDefinitions(method, _interface.base, _interface, _accessor, counterMap, methodNumberMap)»
            «ENDFOR»
            #endif
        «ENDIF»

        «FOR attribute : _interface.attributes.filter[isObservable()]»
            «FTypeGenerator::generateComments(attribute, false)»
            void «_interface.someipStubAdapterClassNameInternal»::«attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(_interface, true)»& value) {
                «attribute.generateFireChangedMethodBody(_interface, _accessor)»
            }
        «ENDFOR»

        «FOR broadcast: _interface.broadcasts»
            «FTypeGenerator::generateComments(broadcast, false)»
            «IF broadcast.selective»
                void «_interface.someipStubAdapterClassNameInternal»::«broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, _interface)») {
                    std::shared_ptr<CommonAPI::SomeIP::ClientId> client = std::dynamic_pointer_cast<CommonAPI::SomeIP::ClientId, CommonAPI::ClientId>(_client);
                «FOR arg: broadcast.outArgs»
                     «val String deploymentType = arg.getDeploymentType(_interface, true)»
                     «val String deployment = arg.getDeploymentRef(arg.array, null, _interface, _accessor)»
                     «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                        CommonAPI::Deployable<«arg.getTypeName(arg, true)», «deploymentType»> deployed_«arg.name»(_«arg.name», «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
                     «ENDIF»
                «ENDFOR»
                  if (client) {
                      CommonAPI::SomeIP::StubEventHelper<CommonAPI::SomeIP::SerializableArguments<«broadcast.outArgs.map[getDeployedTypeName(_interface)].join(', ')»>>
                        ::sendEvent(
                            client->getClientId(),
                            *this,
                            «broadcast.getEventIdentifier(_accessor)»«IF broadcast.outArgs.size > 0»,«ENDIF»
                            «broadcast.outArgs.map[getDeployedElementName(_interface)].join(', ')»
                        );
                   }
                }

                void «_interface.someipStubAdapterClassNameInternal»::«broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, _interface, false)») {
                    std::shared_ptr<CommonAPI::ClientIdList> actualReceiverList;
                    actualReceiverList = _receivers;

                    if(_receivers == NULL)
                        actualReceiverList = «broadcast.stubAdapterClassSubscriberListPropertyName»;

                    for (auto clientIdIterator = actualReceiverList->cbegin();
                               clientIdIterator != actualReceiverList->cend();
                               clientIdIterator++) {
                        if(_receivers == NULL || «broadcast.stubAdapterClassSubscriberListPropertyName»->find(*clientIdIterator) != «broadcast.stubAdapterClassSubscriberListPropertyName»->end()) {
                            «broadcast.stubAdapterClassFireSelectiveMethodName»(*clientIdIterator«IF(!broadcast.outArgs.empty)», «ENDIF»«broadcast.outArgs.map["_" + elementName].join(', ')»);
                        }
                    }
                }

                void «_interface.someipStubAdapterClassNameInternal»::«broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success) {
                    std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                    bool ok = «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionRequestedMethodName»(clientId);
                    if (ok) {
                        «broadcast.stubAdapterClassSubscriberListPropertyName»->insert(clientId);
                        «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::SUBSCRIBED);
                        success = true;
                    } else {
                        success = false;
                    }
                }

                void «_interface.someipStubAdapterClassNameInternal»::«broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId) {
                    std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                    «broadcast.stubAdapterClassSubscriberListPropertyName»->erase(clientId);
                    «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::UNSUBSCRIBED);
                }

                std::shared_ptr<CommonAPI::ClientIdList> const «_interface.someipStubAdapterClassNameInternal»::«broadcast.stubAdapterClassSubscribersMethodName»() {
                    return «broadcast.stubAdapterClassSubscriberListPropertyName»;
                }
            «ELSE»
                void «_interface.someipStubAdapterClassNameInternal»::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(_interface, true) + '& _' + elementName].join(', ')») {
                  «FOR arg: broadcast.outArgs»
                     «val String deploymentType = arg.getDeploymentType(_interface, true)»
                     «val String deployment = arg.getDeploymentRef(arg.array, broadcast, _interface, _accessor)»
                     «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                        CommonAPI::Deployable<«arg.getTypeName(arg, true)», «deploymentType»> deployed_«arg.name»(_«arg.name», «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
                     «ENDIF»
                  «ENDFOR»
                    CommonAPI::SomeIP::StubEventHelper<CommonAPI::SomeIP::SerializableArguments<«broadcast.outArgs.map[getDeployedTypeName(_interface)].join(', ')»>>
                        ::sendEvent(
                            *this,
                            «broadcast.getEventIdentifier(_accessor)»«IF broadcast.outArgs.size > 0»,«ENDIF»
                            «broadcast.outArgs.map[getDeployedElementName(_interface)].join(', ')»
                    );
                }
            «ENDIF»
        «ENDFOR»
        
        «FOR eventGroup : _interface.getSelectiveEventGroups(_accessor)»
            bool «_interface.someipStubAdapterClassNameInternal»::selectiveEventSubscribeHandler_«eventGroup»(CommonAPI::SomeIP::client_id_t _client, bool subscribe) {
                std::shared_ptr<CommonAPI::SomeIP::ClientId> clientId = std::make_shared<CommonAPI::SomeIP::ClientId>(CommonAPI::SomeIP::ClientId(_client));
                bool result = true;
                if (subscribe) {
                	bool localResult;
                    «FOR broadcast : _interface.broadcasts»
                        «IF broadcast.selective && broadcast.getEventGroups(_accessor).contains(eventGroup)»
                            «broadcast.subscribeSelectiveMethodName»(clientId, localResult);
                            result = result && localResult;
                        «ENDIF»
                    «ENDFOR»
                } else {
                    «FOR broadcast : _interface.broadcasts»
                        «IF broadcast.selective && broadcast.getEventGroups(_accessor).contains(eventGroup)»
                            «broadcast.unsubscribeSelectiveMethodName»(clientId);
                        «ENDIF»
                    «ENDFOR»
                }
                return result;
            }
        «ENDFOR»

        «IF _interface.base != null»
            #ifdef WIN32
            «FOR broadcast: _interface.inheritedBroadcasts.filter[selective]»
                «generateBroadcastDispatcherDefinitions(broadcast, _interface)»
            «ENDFOR»
            #endif
        «ENDIF»

        const «_interface.someipStubAdapterHelperClassName»::StubDispatcherTable& «_interface.someipStubAdapterClassNameInternal»::getStubDispatcherTable() {
            return stubDispatcherTable_;
        }

        const CommonAPI::SomeIP::StubAttributeTable& «_interface.someipStubAdapterClassNameInternal»::getStubAttributeTable() {
            return stubAttributeTable_;
        }

        «FOR managed : _interface.managedInterfaces»
            bool «_interface.someipStubAdapterClassNameInternal»::«managed.stubRegisterManagedMethodImpl» {
                if («managed.stubManagedSetName».find(_instance) == «managed.stubManagedSetName».end()) {
                    std::string commonApiAddress = "local:«managed.fullyQualifiedName»:" + _instance;
                    CommonAPI::SomeIP::Address itsSomeIpAddress;
                    CommonAPI::SomeIP::AddressTranslator::get()->translate(commonApiAddress, itsSomeIpAddress);
                    std::shared_ptr<CommonAPI::SomeIP::Factory> itsFactory = CommonAPI::SomeIP::Factory::get();
                    auto stubAdapter = itsFactory->createStubAdapter(_stub, "«managed.fullyQualifiedName»", itsSomeIpAddress, connection_);
                    if(itsFactory->registerManagedService(stubAdapter)) {
                        «managed.stubManagedSetName».insert(_instance);
                        return true;
                    }
                }
                return false;
            }

            bool «_interface.someipStubAdapterClassNameInternal»::«managed.stubDeregisterManagedName»(const std::string& _instance) {
                std::string itsAddress = "local:«managed.fullyQualifiedName»:" + _instance;
                if («managed.stubManagedSetName».find(_instance) != «managed.stubManagedSetName».end()) {
                    std::shared_ptr<CommonAPI::SomeIP::Factory> itsFactory = CommonAPI::SomeIP::Factory::get();
                    if (itsFactory->isRegisteredService(itsAddress)) {
                        itsFactory->unregisterManagedService(itsAddress);
                        «managed.stubManagedSetName».erase(_instance);
                        return true;
                    }
                }
                return false;
            }

            std::set<std::string> &«_interface.someipStubAdapterClassNameInternal»::«managed.stubManagedSetGetterName»() {
                return «managed.stubManagedSetName»;
            }
        «ENDFOR»

        «_interface.someipStubAdapterClassNameInternal»::«_interface.someipStubAdapterClassNameInternal»(
                const CommonAPI::SomeIP::Address &_address,
                const std::shared_ptr<CommonAPI::SomeIP::ProxyConnection> &_connection,
                const std::shared_ptr<CommonAPI::StubBase> &_stub):
                CommonAPI::SomeIP::StubAdapter(_address, _connection),
                «_interface.someipStubAdapterHelperClassName»(
                    _address, 
                    _connection,
                    std::dynamic_pointer_cast<«_interface.stubClassName»>(_stub)),
                «IF _interface.base != null»
                «_interface.base.someipStubAdapterClassNameInternal»(_address, _connection, _stub),
                «ENDIF»
                «setNextSectionInDispatcherNeedsComma(false)»
                stubDispatcherTable_({
                    «_interface.generateDispatcherTableContent(counterMap, methodNumberMap)»
                    «IF _interface.base != null»
                    #ifdef WIN32
                    «_interface.base.generateDispatcherTableContent(counterMap, methodNumberMap)»
                    #endif
                    «ENDIF»
                }),
                stubAttributeTable_(
                    «_interface.generateStubAttributeTableInitializer(_accessor)»
                ) {
                	
                «val itsObservableAttributes = _interface.attributes.filter[isObservable]»
                «IF itsObservableAttributes.size > 0»
                if («_interface.someipStubAdapterHelperClassName»::stub_) {
                	«FOR attribute : itsObservableAttributes»
                	fire«attribute.name.toFirstUpper»AttributeChanged(«_interface.someipStubAdapterHelperClassName»::stub_->get«attribute.name.toFirstUpper»Attribute(nullptr));
                	«ENDFOR»
                }
            «ENDIF»
            «FOR broadcast : _interface.broadcasts»
                «IF broadcast.selective»
                    «broadcast.stubAdapterClassSubscriberListPropertyName» = std::make_shared<CommonAPI::ClientIdList>();
                «ENDIF»   
            «ENDFOR»
            
            «FOR eventGroup : _interface.getSelectiveEventGroups(_accessor)»
            CommonAPI::SomeIP::SubsciptionHandler_t subscribeHandler_«eventGroup» =
                std::bind(&«_interface.someipStubAdapterClassNameInternal»::selectiveEventSubscribeHandler_«eventGroup»,
                          this, std::placeholders::_1, std::placeholders::_2);
            connection_->registerSubsciptionHandler(getSomeIpAddress(), «eventGroup», subscribeHandler_«eventGroup»);
            «ENDFOR»

            «IF _interface.base != null»
                #ifndef WIN32
                auto parentDispatcherTable = «_interface.base.someipStubAdapterClassNameInternal»::getStubDispatcherTable();
                stubDispatcherTable_.insert(parentDispatcherTable.begin(), parentDispatcherTable.end());

                auto parentAttributeTable = «_interface.base.someipStubAdapterClassNameInternal»::getStubAttributeTable();
                stubAttributeTable_.insert(parentAttributeTable.begin(), parentAttributeTable.end());
                #endif
            «ENDIF»
        }

        «_interface.model.generateNamespaceEndDeclaration»
        «_interface.generateVersionNamespaceEnd»
    '''

	var genAttributeSeparator = false;

    def void setGenAttributeSeparator(boolean newValue) {
        genAttributeSeparator = newValue
    }
    
    def private String generateDispatcherTableContent(FInterface _interface, 
    	                                              HashMap<String, Integer> _counters, 
    	                                              HashMap<FMethod, Integer> _methods) '''
        «val accessor = getAccessor(_interface)»
        «setGenAttributeSeparator(false)»
        «FOR attribute : _interface.attributes»
			«FTypeGenerator::generateComments(attribute, false)»
			«val String getIdentifier = attribute.getGetterIdentifier(accessor)» 
            «IF getIdentifier != "0x0"»
            	«IF genAttributeSeparator == true», 
					«setGenAttributeSeparator(false)»
            	«ENDIF»
				«dispatcherTableEntry(_interface, getIdentifier, attribute.someipGetStubDispatcherVariable)»
            «ENDIF»
            «IF !attribute.isReadonly»
				«IF getIdentifier != "0x0" || genAttributeSeparator == true», 
					«setGenAttributeSeparator(false)»
				«ENDIF»
				«dispatcherTableEntry(_interface, attribute.getSetterIdentifier(accessor), attribute.someipSetStubDispatcherVariable)»
            «ENDIF»
            «IF getIdentifier != "0x0" || !attribute.isReadonly»
				«setGenAttributeSeparator(true)»
				«setNextSectionInDispatcherNeedsComma(true)»
            «ENDIF»
        «ENDFOR»
        «IF nextSectionInDispatcherNeedsComma && !_interface.methods.empty»,«ENDIF»
        «FOR method : _interface.methods SEPARATOR ','»
            «FTypeGenerator::generateComments(method, false)»
            «IF _methods.get(method)==0»
                «dispatcherTableEntry(_interface, method.getMethodIdentifier(accessor), method.someipStubDispatcherVariable)»
            «ELSE»
                «dispatcherTableEntry(_interface, method.getMethodIdentifier(accessor), method.someipStubDispatcherVariable+_methods.get(method))»
            «ENDIF»
            «setNextSectionInDispatcherNeedsComma(true)»
        «ENDFOR»
    '''

    def dbusDispatcherTableEntry(FInterface fInterface, String methodName, String dbusSignature, String memberFunctionName) '''
        { { "«methodName»", "«dbusSignature»" }, &«fInterface.absoluteNamespace»::«fInterface.someipStubAdapterClassNameInternal»::«memberFunctionName» }
    '''

    def dispatcherTableEntry(FInterface fInterface, String identifierAsHexString, String memberFunctionName) '''
        { { «identifierAsHexString» }, &«fInterface.absoluteNamespace»::«fInterface.someipStubAdapterClassNameInternal»::«memberFunctionName» }
    '''

    def private getAbsoluteNamespace(FModelElement fModelElement) {
        fModelElement.model.name.replace('.', '::')
    }

    def private someipStubAdapterHeaderFile(FInterface fInterface) {
        fInterface.elementName + "SomeIPStubAdapter.hpp"
    }

    def private someipStubAdapterHeaderPath(FInterface fInterface) {
        fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.someipStubAdapterHeaderFile
    }

    def private someipStubAdapterSourceFile(FInterface fInterface) {
        fInterface.elementName + "SomeIPStubAdapter.cpp"
    }

    def private someipStubAdapterSourcePath(FInterface fInterface) {
        fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.someipStubAdapterSourceFile
    }

    def private someipStubAdapterClassName(FInterface fInterface) {
        fInterface.elementName + 'SomeIPStubAdapter'
    }

    def private someipStubAdapterClassNameInternal(FInterface fInterface) {
        fInterface.someipStubAdapterClassName + 'Internal'
    }
    
    def private someipStubAdapterHelperClassName(FInterface fInterface) {
        fInterface.elementName + 'SomeIPStubAdapterHelper'
    }

    def private getAllInTypes(FMethod fMethod) {
        fMethod.inArgs.map[getTypeName(fMethod, true)].join(', ')
    }

    def private getAllOutTypes(FMethod fMethod) {
        var types = fMethod.outArgs.map[getTypeName(fMethod, true)].join(', ')

        if (fMethod.hasError) {
            if (!fMethod.outArgs.empty)
                types = ', ' + types
            types = fMethod.getErrorNameReference(fMethod.eContainer) + types
        }

        return types
    }
    
    def private someipStubDispatcherVariable(FMethod fMethod) {
        fMethod.elementName.toFirstLower + 'StubDispatcher'
    }

    def private someipGetStubDispatcherVariable(FAttribute fAttribute) {
        fAttribute.getMethodName + 'StubDispatcher'
    }

    def private someipSetStubDispatcherVariable(FAttribute fAttribute) {
        fAttribute.setMethodName + 'StubDispatcher'
    }

    def private dbusStubDispatcherVariable(FBroadcast fBroadcast) {
        var returnVal = fBroadcast.elementName.toFirstLower

        if(fBroadcast.selective)
            returnVal = returnVal + 'Selective'

        returnVal = returnVal + 'StubDispatcher'

        return returnVal
    }

    def private dbusStubDispatcherVariableSubscribe(FBroadcast fBroadcast) {
        "subscribe" + fBroadcast.dbusStubDispatcherVariable.toFirstUpper
    }

    def private dbusStubDispatcherVariableUnsubscribe(FBroadcast fBroadcast) {
        "unsubscribe" + fBroadcast.dbusStubDispatcherVariable.toFirstUpper
    }

    var nextSectionInDispatcherNeedsComma = false;
	
    def void setNextSectionInDispatcherNeedsComma(boolean newValue) {
        nextSectionInDispatcherNeedsComma = newValue
    }

    def private generateFireChangedMethodBody(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) '''
        «val String deploymentType = _attribute.getDeploymentType(_interface, true)»
        «val String deployment = _attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor)»
        «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
            CommonAPI::Deployable<«_attribute.getTypeName(_interface, true)», «deploymentType»> deployedValue(value, «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
        «ENDIF»
        CommonAPI::SomeIP::StubEventHelper<
            CommonAPI::SomeIP::SerializableArguments<
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                CommonAPI::Deployable<
                    «_attribute.getTypeName(_interface, true)»,
                    «deploymentType»
                >
            «ELSE»
                «_attribute.getTypeName(_interface, true)»
            «ENDIF»
            >
        >::sendEvent(
            *this,
            «_attribute.getNotifierIdentifier(_accessor)»,
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»deployedValue«ELSE»value«ENDIF»
        );
    '''
    
    def private generateStubAttributeTableInitializer(FInterface _interface, PropertyAccessor _accessor) '''
    '''
    
}