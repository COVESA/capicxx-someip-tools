/* Copyright (C) 2014, 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import java.util.HashMap
import java.util.List
import java.util.LinkedList
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.deploymodel.core.FDeployedProvider
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.genivi.commonapi.core.generator.FTypeGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.franca.core.franca.FArgument
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP

class FInterfaceSomeIPStubAdapterGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaSomeIPGeneratorExtensions
    @Inject private extension FrancaSomeIPDeploymentAccessorHelper

    def generateStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess, PropertyAccessor deploymentAccessor, List<FDProvider> providers, IResource modelid) {
        if(FPreferencesSomeIP::getInstance.getPreference(PreferenceConstantsSomeIP::P_GENERATE_CODE_SOMEIP, "true").equals("true")) {
            fileSystemAccess.generateFile(fInterface.someipStubAdapterHeaderPath, PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP,
                fInterface.generateStubAdapterHeader(deploymentAccessor, modelid))
            fileSystemAccess.generateFile(fInterface.someipStubAdapterSourcePath, PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP,
                fInterface.generateStubAdapterSource(deploymentAccessor, providers, modelid))
        }
        else {
            fileSystemAccess.generateFile(fInterface.someipStubAdapterHeaderPath, PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP,
                PreferenceConstantsSomeIP::NO_CODE)
            fileSystemAccess.generateFile(fInterface.someipStubAdapterSourcePath, PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP,
                PreferenceConstantsSomeIP::NO_CODE)
        }
    }

    def private generateStubAdapterHeader(FInterface _interface, PropertyAccessor _accessor, IResource _modelid) '''
        «generateCommonApiSomeIPLicenseHeader()»
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

        #include <CommonAPI/SomeIP/AddressTranslator.hpp>
        #include <CommonAPI/SomeIP/StubAdapterHelper.hpp>
        #include <CommonAPI/SomeIP/StubAdapter.hpp>
        #include <CommonAPI/SomeIP/Factory.hpp>
        #include <CommonAPI/SomeIP/Types.hpp>
        #include <CommonAPI/SomeIP/Constants.hpp>

        #undef COMMONAPI_INTERNAL_COMPILATION

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»

        template <typename _Stub = «_interface.stubFullClassName», typename... _Stubs>
        class «_interface.someipStubAdapterClassNameInternal»
            : public virtual «_interface.stubAdapterClassName»,
        «IF _interface.base == null»      public CommonAPI::SomeIP::StubAdapterHelper< _Stub, _Stubs...>«ENDIF»
        «IF _interface.base != null»      public «_interface.base.getTypeCollectionName(_interface)»SomeIPStubAdapterInternal<_Stub, _Stubs...>«ENDIF»
        {
        public:
            typedef CommonAPI::SomeIP::StubAdapterHelper< _Stub, _Stubs...> «_interface.someipStubAdapterHelperClassName»;

            ~«_interface.someipStubAdapterClassNameInternal»() {
                «FOR broadcast : _interface.broadcasts»
                    «IF broadcast.selective»
                        CommonAPI::SomeIP::StubAdapter::connection_->unregisterSubsciptionHandler(CommonAPI::SomeIP::StubAdapter::getSomeIpAddress(), «broadcast.getEventGroups(_accessor).head»);
                    «ENDIF»
                «ENDFOR»
                deactivateManagedInstances();
                «_interface.someipStubAdapterHelperClassName»::deinit();
            }

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
                    «IF !broadcast.isErrorType(_accessor)»
                        void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(_interface, true) + '& ' + elementName].join(', ')»);
                    «ENDIF»
                «ENDIF»

            «ENDFOR»
            «FOR managed: _interface.managedInterfaces»
                «managed.stubRegisterManagedMethod»;
                bool «managed.stubDeregisterManagedName»(const std::string&);
                std::set<std::string>& «managed.stubManagedSetGetterName»();

            «ENDFOR»
            void deactivateManagedInstances() {
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

            «var counterMap = new HashMap<String, Integer>()»
            «var methodNumberMap = new HashMap<FMethod, Integer>()»
            «_interface.generateMethodDispatcherDeclarations(_interface, counterMap, methodNumberMap, _accessor)»

            «_interface.someipStubAdapterClassNameInternal»(
                const CommonAPI::SomeIP::Address &_address,
                const std::shared_ptr<CommonAPI::SomeIP::ProxyConnection> &_connection,
                const std::shared_ptr<CommonAPI::StubBase> &_stub):
                CommonAPI::SomeIP::StubAdapter(_address, _connection),
                «IF _interface.base == null»«_interface.someipStubAdapterHelperClassName»(
                    _address,
                    _connection,
                    std::dynamic_pointer_cast< «_interface.stubClassName»>(_stub))
                «ENDIF»
                «IF _interface.base != null»
                    «_interface.base.getTypeCollectionName(_interface)»SomeIPStubAdapterInternal<_Stub, _Stubs...>(_address, _connection, _stub)
                «ENDIF»
            {

                «_interface.generateDispatcherTableContent(counterMap, methodNumberMap)»
                «_interface.generateStubAttributeTableInitializer(_accessor)»
                «FOR broadcast : _interface.broadcasts»
                    «IF broadcast.selective»
                        «broadcast.getStubAdapterClassSubscriberListPropertyName» = std::make_shared<CommonAPI::ClientIdList>();
                        CommonAPI::SomeIP::SubsciptionHandler_t «broadcast.className»SubscribeHandler =
                            std::bind(&«_interface.someipStubAdapterClassNameInternal»::«broadcast.className»Handler,
                            this, std::placeholders::_1, std::placeholders::_2);

                        CommonAPI::SomeIP::StubAdapter::connection_->registerSubsciptionHandler(CommonAPI::SomeIP::StubAdapter::getSomeIpAddress(), «broadcast.getEventGroups(_accessor).head», «broadcast.className»SubscribeHandler);
                    «ENDIF»

                «ENDFOR»
                «IF (!_interface.attributes.filter[isObservable()].empty)»
                    std::shared_ptr<CommonAPI::SomeIP::ClientId> clientId = std::make_shared<CommonAPI::SomeIP::ClientId>(0xFFFF);

                «ENDIF»
                // Provided events/fields
                «FOR broadcast : _interface.broadcasts»
                    «IF !broadcast.isErrorType(_accessor)»
                        {
                            std::set<CommonAPI::SomeIP::eventgroup_id_t> itsEventGroups;
                            «FOR eventgroup : broadcast.getEventGroups(_accessor)»
                                itsEventGroups.insert(CommonAPI::SomeIP::eventgroup_id_t(«eventgroup»));
                            «ENDFOR»
                            CommonAPI::SomeIP::StubAdapter::registerEvent(«broadcast.getEventIdentifier(_accessor)», itsEventGroups, false);
                        }
                    «ENDIF»
                «ENDFOR»
                «FOR attribute : _interface.attributes»
                    «IF attribute.observable»
                        {
                            std::set<CommonAPI::SomeIP::eventgroup_id_t> itsEventGroups;
                            «FOR eventgroup : attribute.getNotifierEventGroups(_accessor)»
                            itsEventGroups.insert(CommonAPI::SomeIP::eventgroup_id_t(«eventgroup»));
                            «ENDFOR»
                            CommonAPI::SomeIP::StubAdapter::registerEvent(«attribute.getNotifierIdentifier(_accessor)», itsEventGroups, true);
                            «attribute.stubAdapterClassFireChangedMethodName»(std::dynamic_pointer_cast< «_interface.stubFullClassName»>(_stub)->«attribute.getMethodName»(clientId));
                        }

                    «ENDIF»
                «ENDFOR»
            }

        private:
        «FOR broadcast: _interface.broadcasts»
            «IF broadcast.selective»
                std::mutex «broadcast.className»Mutex_;
                bool «broadcast.className»Handler(CommonAPI::SomeIP::client_id_t _client, bool subscribe);
            «ENDIF»
        «ENDFOR»
        «FOR managed: _interface.managedInterfaces»
            std::set<std::string> «managed.stubManagedSetName»;

        «ENDFOR»
        };

        template <typename _Stub, typename... _Stubs>
        CommonAPI::SomeIP::GetAttributeStubDispatcher<
            «_interface.stubFullClassName»,
            CommonAPI::Version
            > «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::get«_interface.elementName»InterfaceVersionStubDispatcher(&«_interface.stubClassName»::lockInterfaceVersionAttribute, &«_interface.stubClassName»::getInterfaceVersion, false);

        «FOR attribute : _interface.attributes»
            «generateAttributeDispatcherDefinitions(attribute, _interface, _accessor)»

        «ENDFOR»
        «{counterMap = new HashMap<String, Integer>(); ""}»
        «{methodNumberMap = new HashMap<FMethod, Integer>(); ""}»
        «FOR method : _interface.methods»
            «generateMethodDispatcherDefinitions(method, _interface, _interface, _accessor, counterMap, methodNumberMap)»

        «ENDFOR»
        «FOR attribute : _interface.attributes.filter[isObservable()]»
            «FTypeGenerator::generateComments(attribute, false)»
            template <typename _Stub, typename... _Stubs>
            void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(_interface, true)»& value) {
                «attribute.generateFireChangedMethodBody(_interface, _accessor)»
            }

        «ENDFOR»
        «FOR broadcast: _interface.broadcasts»
            «FTypeGenerator::generateComments(broadcast, false)»
            «IF broadcast.selective»
                template <typename _Stub, typename... _Stubs>
                void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, _interface)») {
                    std::shared_ptr<CommonAPI::SomeIP::ClientId> client = std::dynamic_pointer_cast<CommonAPI::SomeIP::ClientId, CommonAPI::ClientId>(_client);
                    «FOR arg: broadcast.outArgs»
                         «val String deploymentType = arg.getDeploymentType(_interface, true)»
                         «val String deployment = arg.getDeploymentRef(arg.array, broadcast, _interface, _accessor)»
                         «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                              CommonAPI::Deployable< «arg.getTypeName(arg, true)», «deploymentType»> deployed_«arg.name»(_«arg.name», «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
                         «ENDIF»
                    «ENDFOR»
                    if (client) {
                        CommonAPI::SomeIP::StubEventHelper<CommonAPI::SomeIP::SerializableArguments< «broadcast.outArgs.map[getDeployedTypeName(_interface, _accessor)].join(', ')»>>
                          ::sendEvent(
                              client->getClientId(),
                              *this,
                              «broadcast.getEventIdentifier(_accessor)»,
                              «broadcast.getEndianess(_accessor)»«IF broadcast.outArgs.size > 0»,«ENDIF»
                              «broadcast.outArgs.map[getDeployedElementName(_interface, _accessor)].join(', ')»
                          );
                   }
                }

                template <typename _Stub, typename... _Stubs>
                void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, _interface, false)») {
                    std::shared_ptr<CommonAPI::ClientIdList> actualReceiverList;
                    actualReceiverList = _receivers;

                    if(_receivers == NULL) {
                        std::lock_guard < std::mutex > itsLock(«broadcast.className»Mutex_);
                        if («broadcast.stubAdapterClassSubscriberListPropertyName» != NULL)
                            actualReceiverList = std::make_shared<CommonAPI::ClientIdList>(*«broadcast.stubAdapterClassSubscriberListPropertyName»);
                    }

                    if(actualReceiverList == NULL)
                        return;

                    for (auto clientIdIterator = actualReceiverList->cbegin();
                               clientIdIterator != actualReceiverList->cend();
                               clientIdIterator++) {
                        bool found(false);
                        {
                            std::lock_guard < std::mutex > itsLock(«broadcast.className»Mutex_);
                            found = («broadcast.stubAdapterClassSubscriberListPropertyName»->find(*clientIdIterator) != «broadcast.stubAdapterClassSubscriberListPropertyName»->end());
                        }
                        if(_receivers == NULL || found) {
                            «broadcast.stubAdapterClassFireSelectiveMethodName»(*clientIdIterator«IF(!broadcast.outArgs.empty)», «ENDIF»«broadcast.outArgs.map["_" + elementName].join(', ')»);
                        }
                    }
                }

                template <typename _Stub, typename... _Stubs>
                void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success) {
                    bool ok = «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionRequestedMethodName»(clientId);
                    if (ok) {
                        {
                            std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                            «broadcast.stubAdapterClassSubscriberListPropertyName»->insert(clientId);
                        }
                        «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::SUBSCRIBED);
                        success = true;
                    } else {
                        success = false;
                    }
                }
                template <typename _Stub, typename... _Stubs>
                void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId) {
                    «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::UNSUBSCRIBED);
                    {
                        std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                        «broadcast.stubAdapterClassSubscriberListPropertyName»->erase(clientId);
                    }
                }

                template <typename _Stub, typename... _Stubs>
                std::shared_ptr<CommonAPI::ClientIdList> const «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassSubscribersMethodName»() {
                    std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                    return std::make_shared<CommonAPI::ClientIdList>(*«broadcast.stubAdapterClassSubscriberListPropertyName»);
                }

                template <typename _Stub, typename... _Stubs>
                bool «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.className»Handler(CommonAPI::SomeIP::client_id_t _client, bool subscribe) {
                    std::shared_ptr<CommonAPI::SomeIP::ClientId> clientId = std::make_shared<CommonAPI::SomeIP::ClientId>(CommonAPI::SomeIP::ClientId(_client));
                    bool result = true;
                    if (subscribe) {
                        «broadcast.subscribeSelectiveMethodName»(clientId, result);
                    } else {
                        «broadcast.unsubscribeSelectiveMethodName»(clientId);
                    }
                    return result;
                }

            «ELSE»
                «IF !broadcast.isErrorType(_accessor)»
                    template <typename _Stub, typename... _Stubs>
                    void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(_interface, true) + '& _' + elementName].join(', ')») {
                        «FOR arg: broadcast.outArgs»
                            «val String deploymentType = arg.getDeploymentType(_interface, true)»
                            «val String deployment = arg.getDeploymentRef(arg.array, broadcast, _interface, _accessor)»
                            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                                CommonAPI::Deployable< «arg.getTypeName(arg, true)», «deploymentType»> deployed_«arg.name»(_«arg.name», «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
                            «ENDIF»
                        «ENDFOR»
                        CommonAPI::SomeIP::StubEventHelper<CommonAPI::SomeIP::SerializableArguments< «broadcast.outArgs.map[getDeployedTypeName(_interface, _accessor)].join(', ')»>>
                            ::sendEvent(
                                *this,
                                «broadcast.getEventIdentifier(_accessor)»,
                                «broadcast.getEndianess(_accessor)»«IF broadcast.outArgs.size > 0»,«ENDIF»
                                «broadcast.outArgs.map[getDeployedElementName(_interface, _accessor)].join(', ')»
                        );
                    }
                «ENDIF»
            «ENDIF»

        «ENDFOR»
        «FOR managed : _interface.managedInterfaces»
            template <typename _Stub, typename... _Stubs>
            bool «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«managed.stubRegisterManagedMethodImpl» {
                if («managed.stubManagedSetName».find(_instance) == «managed.stubManagedSetName».end()) {
                    std::string commonApiAddress = "local:«managed.fullyQualifiedNameWithVersion»:" + _instance;
                    CommonAPI::SomeIP::Address itsSomeIpAddress;
                    CommonAPI::SomeIP::AddressTranslator::get()->translate(commonApiAddress, itsSomeIpAddress);
                    std::shared_ptr<CommonAPI::SomeIP::Factory> itsFactory = CommonAPI::SomeIP::Factory::get();
                    auto stubAdapter = itsFactory->createStubAdapter(_stub, "«managed.fullyQualifiedNameWithVersion»", itsSomeIpAddress, CommonAPI::SomeIP::StubAdapter::connection_);
                    if(itsFactory->registerManagedService(stubAdapter)) {
                        «managed.stubManagedSetName».insert(_instance);
                        return true;
                    }
                }
                return false;
            }

            template <typename _Stub, typename... _Stubs>
            bool «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«managed.stubDeregisterManagedName»(const std::string& _instance) {
                std::string itsAddress = "local:«managed.fullyQualifiedNameWithVersion»:" + _instance;
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

            template <typename _Stub, typename... _Stubs>
            std::set<std::string> &«_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«managed.stubManagedSetGetterName»() {
                return «managed.stubManagedSetName»;
            }

        «ENDFOR»
        template <typename _Stub = «_interface.stubFullClassName», typename... _Stubs>
        class «_interface.someipStubAdapterClassName»
            : public «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>,
              public std::enable_shared_from_this< «_interface.someipStubAdapterClassName»<_Stub, _Stubs...>> {
        public:
            «_interface.someipStubAdapterClassName»(const CommonAPI::SomeIP::Address &_address,
                                                    const std::shared_ptr<CommonAPI::SomeIP::ProxyConnection> &_connection,
                                                    const std::shared_ptr<CommonAPI::StubBase> &_stub)
                : CommonAPI::SomeIP::StubAdapter(_address, _connection),
                  «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>(_address, _connection, _stub) {
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
                                                            HashMap<FMethod, Integer> _methods,
                                                            PropertyAccessor _accessor) '''
        «val accessor = getAccessor(_interface)»
        «FOR method : _interface.methods»
            «FTypeGenerator::generateComments(method, false)»
            «IF !method.isFireAndForget»
                «var errorReplyTypes = new LinkedList()»
                «FOR broadcast : _interface.broadcasts»
                    «IF broadcast.isErrorType(method, _accessor)»
                        «{errorReplyTypes.add(broadcast.errorReplyTypes(method, _accessor));""}»
                        «broadcast.generateErrorReplyCallback(_interface, method, _accessor)»
                    «ENDIF»
                «ENDFOR»
                
                static CommonAPI::SomeIP::MethodWithReplyStubDispatcher<
                    «_interface.stubFullClassName»,
                    std::tuple< «method.allInTypes»>,
                    std::tuple< «method.allOutTypes»>,
                    std::tuple< «method.inArgs.getDeploymentTypes(_interface, accessor)»>,
                    std::tuple< «method.getErrorDeploymentType(true)»«method.outArgs.getDeploymentTypes(_interface, accessor)»>«IF errorReplyTypes.size > 0»,«ENDIF»
                    «errorReplyTypes.map['std::function< void (' + it + ')>'].join(',\n')»
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
                    std::tuple< «method.allInTypes»>,
                    std::tuple< «method.inArgs.getDeploymentTypes(_interface, accessor)»>
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
                                                                       HashMap<FMethod, Integer> _methods,
                                                                       PropertyAccessor _accessor) '''
        «_interface.generateMethodDispatcherDeclarations(_container, _counters, _methods, _accessor)»
        «IF _interface.base != null»
            «_interface.base.recursivelyGenerateMethodDispatcherDeclarations(_container, _counters, _methods, _accessor)»
        «ENDIF»
    '''

    def private generateAttributeDispatcherDefinitions(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) '''
            «FTypeGenerator::generateComments(_attribute, false)»
            «val typeName = _attribute.getTypeName(_interface, true)»
            «val String deploymentType = _attribute.getDeploymentType(_interface, true)»
            «val String getIdentifier = _attribute.getGetterIdentifier(_accessor)»
            «IF getIdentifier != "0x0"»
            template <typename _Stub, typename... _Stubs>
            CommonAPI::SomeIP::GetAttributeStubDispatcher<
                «_interface.stubFullClassName»,
                «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                «deploymentType»«ENDIF»
            > «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«_attribute.someipGetStubDispatcherVariable»(
                &«_interface.stubClassName»::«_attribute.stubClassLockMethodName»,
                &«_interface.stubClassName»::«_attribute.stubClassGetMethodName», «_attribute.getEndianess(_accessor)»«IF _accessor.hasDeployment(_attribute)», «_attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor)»«ENDIF»);
            «ENDIF»
            «IF !_attribute.isReadonly»
                template <typename _Stub, typename... _Stubs>
                CommonAPI::SomeIP::Set«IF _attribute.observable»Observable«ENDIF»AttributeStubDispatcher<
                    «_interface.stubFullClassName»,
                    «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                    «deploymentType»«ENDIF»
                > «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«_attribute.someipSetStubDispatcherVariable»(
                    &«_interface.stubClassName»::«_attribute.stubClassLockMethodName»,
                    &«_interface.stubClassName»::«_attribute.stubClassGetMethodName»,
                    &«_interface.stubRemoteEventClassName»::«_attribute.stubRemoteEventClassSetMethodName»,
                    &«_interface.stubRemoteEventClassName»::«_attribute.stubRemoteEventClassChangedMethodName»,
                    «IF _attribute.observable»&«_interface.stubAdapterClassName»::«_attribute.stubAdapterClassFireChangedMethodName»,«ENDIF»
                    «_attribute.getEndianess(_accessor)»«IF _accessor.hasDeployment(_attribute)»,
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
            «var errorReplyTypes = new LinkedList()»
            «var errorReplyCallbacks = new LinkedList()»
            «FOR broadcast : _interface.broadcasts»
                «IF broadcast.isErrorType(_method, _accessor)»
                    «{errorReplyTypes.add(broadcast.errorReplyTypes(_method, _accessor));""}»
                    «{errorReplyCallbacks.add('std::bind(&' + _interface.someipStubAdapterClassNameInternal + '<_Stub, _Stubs...>::' +
                        broadcast.errorReplyCallbackName(_accessor) + ', ' + broadcast.errorReplyCallbackBindArgs(_accessor) + ')'
                    );""}»
                «ENDIF»
            «ENDFOR»
            template <typename _Stub, typename... _Stubs>
            CommonAPI::SomeIP::MethodWithReplyStubDispatcher<
                «_interface.stubFullClassName»,
                std::tuple< «_method.allInTypes»>,
                std::tuple< «_method.allOutTypes»>,
                std::tuple< «_method.inArgs.getDeploymentTypes(_interface, _accessor)»>,
                std::tuple< «_method.getErrorDeploymentType(true)»«_method.outArgs.getDeploymentTypes(_interface, _accessor)»>«IF errorReplyTypes.size > 0»,«ENDIF»
                «errorReplyTypes.map['std::function< void (' + it + ')>'].join(',\n')»
            «IF !(counterMap.containsKey(_method.someipStubDispatcherVariable))»
                «{counterMap.put(_method.someipStubDispatcherVariable, 0);  methodnumberMap.put(_method, 0);""}»
                > «_thisInterface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«_method.someipStubDispatcherVariable»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»,
                    «_method.getDeployments(_interface, _accessor, true, false)»,
                    «_method.getDeployments(_interface, _accessor, false, true)»«IF errorReplyCallbacks.size > 0»,«'\n' + errorReplyCallbacks.map[it].join(',\n')»«ENDIF»);
            «ELSE»
                «{counterMap.put(_method.someipStubDispatcherVariable, counterMap.get(_method.someipStubDispatcherVariable) + 1);  methodnumberMap.put(_method, counterMap.get(_method.someipStubDispatcherVariable));""}»
                > «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«_method.someipStubDispatcherVariable»«Integer::toString(counterMap.get(_method.someipStubDispatcherVariable))»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»
                    «_method.getDeployments(_interface, _accessor, true, false)»,
                    «_method.getDeployments(_interface, _accessor, false, true)»«IF errorReplyCallbacks.size > 0»,«'\n' + errorReplyCallbacks.map[it].join(',\n')»«ENDIF»);
            «ENDIF»
        «ELSE»
            template <typename _Stub, typename... _Stubs>
            CommonAPI::SomeIP::MethodStubDispatcher<
                «_interface.stubFullClassName»,
                std::tuple< «_method.allInTypes»>,
                std::tuple< «_method.inArgs.getDeploymentTypes(_interface, _accessor)»>
            «IF !(counterMap.containsKey(_method.someipStubDispatcherVariable))»
                «{counterMap.put(_method.someipStubDispatcherVariable, 0); methodnumberMap.put(_method, 0);""}»
                > «_thisInterface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«_method.someipStubDispatcherVariable»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»,
                    «_method.getDeployments(_interface, _accessor, true, false)»);
            «ELSE»
                «{counterMap.put(_method.someipStubDispatcherVariable, counterMap.get(_method.someipStubDispatcherVariable) + 1);  methodnumberMap.put(_method, counterMap.get(_method.someipStubDispatcherVariable));""}»
                > «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«_method.someipStubDispatcherVariable»«Integer::toString(counterMap.get(_method.someipStubDispatcherVariable))»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»,
                    «_method.getDeployments(_interface, _accessor, true, false)»);
            «ENDIF»
        «ENDIF»
    '''

   def private getDeployedTypeName(FArgument _arg, FInterface _interface, PropertyAccessor _accessor)'''
            «val String deploymentType = _arg.getDeploymentType(_interface, true)»
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""» CommonAPI::Deployable< «_arg.getTypeName(_interface, true)», «deploymentType» > «ELSE» «_arg.getTypeName(_interface, true)»«ENDIF»
   '''

   def private  getDeployedElementName(FArgument _arg, FInterface _interface, PropertyAccessor _accessor)'''
    «val String deploymentType = _arg.getDeploymentType(_interface, true)»
    «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""» deployed_«_arg.name» «ELSE»_«_arg.name»«ENDIF»
   '''
    def private String getInterfaceHierarchy(FInterface fInterface) {
        if (fInterface.base == null) {
            fInterface.stubFullClassName
        } else {
            fInterface.stubFullClassName + ", " + fInterface.base.interfaceHierarchy
        }
    }
    def private generateStubAdapterSource(FInterface _interface, PropertyAccessor _accessor, List<FDProvider> providers, IResource _modelid) '''
        «generateCommonApiSomeIPLicenseHeader()»
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
            return std::make_shared< «_interface.someipStubAdapterClassName»<«_interface.interfaceHierarchy»>>(_address, _connection, _stub);
        }

        void initialize«_interface.someipStubAdapterClassName»() {
            «FOR p : providers»
                «val PropertyAccessor providerAccessor = new PropertyAccessor(new FDeployedProvider(p))»
                «FOR i : p.instances.filter[target == _interface]»
                    CommonAPI::SomeIP::AddressTranslator::get()->insert(
                        "local:«_interface.fullyQualifiedNameWithVersion»:«providerAccessor.getInstanceId(i)»",
                         «_interface.getSomeIpServiceID», 0x«Integer.toHexString(
                            providerAccessor.getSomeIpInstanceID(i))», «_interface.version.major», «_interface.version.minor»);
                «ENDFOR»
            «ENDFOR»
            CommonAPI::SomeIP::Factory::get()->registerStubAdapterCreateMethod(
                «_interface.elementName»::getInterface(),
                &create«_interface.someipStubAdapterClassName»);
        }

        INITIALIZER(register«_interface.someipStubAdapterClassName») {
            CommonAPI::SomeIP::Factory::get()->registerInterface(initialize«_interface.someipStubAdapterClassName»);
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
                «dispatcherTableEntry(_interface, getIdentifier, attribute.someipGetStubDispatcherVariable)»
            «ENDIF»
            «IF !attribute.isReadonly»
                «dispatcherTableEntry(_interface, attribute.getSetterIdentifier(accessor), attribute.someipSetStubDispatcherVariable)»
            «ENDIF»
        «ENDFOR»

        «FOR method : _interface.methods»
            «FTypeGenerator::generateComments(method, false)»
            «IF _methods.get(method)==0»
                «dispatcherTableEntry(_interface, method.getMethodIdentifier(accessor), method.someipStubDispatcherVariable)»
            «ELSE»
                «dispatcherTableEntry(_interface, method.getMethodIdentifier(accessor), method.someipStubDispatcherVariable+_methods.get(method))»
            «ENDIF»
        «ENDFOR»
    '''


    def dispatcherTableEntry(FInterface fInterface, String identifierAsHexString, String memberFunctionName) '''
        «fInterface.someipStubAdapterHelperClassName»::addStubDispatcher( { «identifierAsHexString» }, &«memberFunctionName» );
    '''

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

    var nextSectionInDispatcherNeedsComma = false;

    def void setNextSectionInDispatcherNeedsComma(boolean newValue) {
        nextSectionInDispatcherNeedsComma = newValue
    }

    def private generateFireChangedMethodBody(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) '''
        «val String deploymentType = _attribute.getDeploymentType(_interface, true)»
        «val String deployment = _attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor)»
        «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
            CommonAPI::Deployable< «_attribute.getTypeName(_interface, true)», «deploymentType»> deployedValue(value, «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
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
            «_attribute.getEndianess(_accessor)»,
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»deployedValue«ELSE»value«ENDIF»
        );
    '''

    def private generateStubAttributeTableInitializer(FInterface _interface, PropertyAccessor _accessor) '''
    '''

    def private generateErrorReplyCallback(FBroadcast _broadcast, FInterface _interface, FMethod _method, PropertyAccessor _accessor) '''
            
        static void «_broadcast.errorReplyCallbackName(_accessor)»(«_broadcast.generateErrorReplyCallbackSignature(_method, _accessor)») {
            «IF _broadcast.errorArgs(_accessor).size > 1»
                auto args = std::make_tuple(
                    «_broadcast.errorArgs(_accessor).map[it.getDeployable(_interface, _accessor) + '(' + '_' + it.elementName + ', ' + getDeploymentRef(it.array, _broadcast, _interface, _accessor) + ')'].join(",\n")  + ");"»
            «ELSE»
                auto args = std::make_tuple();
            «ENDIF»
            (void)args;
            //sayHelloStubDispatcher.sendErrorReplyMessage(_callId, «_broadcast.errorName(_accessor)», args);
        }
    '''
}
