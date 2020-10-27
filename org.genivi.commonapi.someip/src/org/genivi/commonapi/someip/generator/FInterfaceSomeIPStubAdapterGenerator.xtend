/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
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
import org.franca.deploymodel.dsl.fDeploy.FDExtensionRoot
import org.franca.deploymodel.ext.providers.FDeployedProvider
import org.franca.deploymodel.ext.providers.ProviderUtils
import org.genivi.commonapi.core.generator.FTypeGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.franca.core.franca.FArgument
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP

class FInterfaceSomeIPStubAdapterGenerator {
    @Inject extension FrancaGeneratorExtensions
    @Inject extension FrancaSomeIPGeneratorExtensions
    @Inject extension FrancaSomeIPDeploymentAccessorHelper

    def generateStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess, PropertyAccessor deploymentAccessor, List<FDExtensionRoot> providers, IResource modelid) {
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
        «IF _interface.base !== null»
            #include <«_interface.base.someipStubAdapterHeaderPath»>
        «ENDIF»
        «val DeploymentHeaders = _interface.getDeploymentInputIncludes(_accessor)»
        «DeploymentHeaders.map["#include <" + it + ">"].join("\n")»

        «startInternalCompilation»

        #include <CommonAPI/SomeIP/AddressTranslator.hpp>
        #include <CommonAPI/SomeIP/StubAdapterHelper.hpp>
        #include <CommonAPI/SomeIP/StubAdapter.hpp>
        #include <CommonAPI/SomeIP/Factory.hpp>
        #include <CommonAPI/SomeIP/Types.hpp>
        #include <CommonAPI/SomeIP/Constants.hpp>

        «endInternalCompilation»

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»

        template <typename _Stub = «_interface.stubFullClassName», typename... _Stubs>
        class «_interface.someipStubAdapterClassNameInternal»
            : public virtual «_interface.stubAdapterClassName»,
        «IF _interface.base === null»      public CommonAPI::SomeIP::StubAdapterHelper< _Stub, _Stubs...>,
              public std::enable_shared_from_this< «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>>
        «ELSE»      public «_interface.base.getTypeCollectionName(_interface)»SomeIPStubAdapterInternal<_Stub, _Stubs...>
        «ENDIF»
        {
        public:
            typedef CommonAPI::SomeIP::StubAdapterHelper< _Stub, _Stubs...> «_interface.someipStubAdapterHelperClassName»;

            ~«_interface.someipStubAdapterClassNameInternal»() {
                deactivateManagedInstances();
                «_interface.someipStubAdapterHelperClassName»::deinit();
            }

            «FOR attribute : _interface.attributes»
                «IF attribute.isObservable»
                    «FTypeGenerator::generateComments(attribute, false)»
                    void «attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(_interface, true)» &_value);
                    
                «ENDIF»
            «ENDFOR»
            «FOR broadcast: _interface.broadcasts»
                «FTypeGenerator::generateComments(broadcast, false)»
                «IF broadcast.selective»
                    void «broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, _interface)»);
                    void «broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, _interface, true)»);
                    void «broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> _client, bool &_success);
                    void «broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> _client);
                    std::shared_ptr<CommonAPI::ClientIdList> const «broadcast.stubAdapterClassSubscribersMethodName»();

                «ELSE»
                    «IF !broadcast.isErrorType(_accessor)»
                        void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(_interface, true) + ' &_' + elementName].join(', ')»);

                    «ENDIF»
                «ENDIF»
            «ENDFOR»
            «FOR managed: _interface.managedInterfaces»
                «managed.stubRegisterManagedMethod»;
                bool «managed.stubDeregisterManagedName»(const std::string&);
                std::set<std::string>& «managed.stubManagedSetGetterName»();

            «ENDFOR»
            «IF _interface.managedInterfaces.empty»
            void deactivateManagedInstances() {}
            «ELSE»
            void deactivateManagedInstances() {
                std::set<std::string>::iterator iter;
                std::set<std::string>::iterator iterNext;
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
            «ENDIF»
            
            «IF _interface.base !== null»
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
            CommonAPI::SomeIP::GetAttributeStubDispatcher<
                «_interface.stubFullClassName»,
                CommonAPI::Version
            > get«_interface.elementName»InterfaceVersionStubDispatcher;

            «generateAttributeDispatcherDeclarations(_interface, _accessor)»
            «var dispatcherDefinitionsList = new LinkedList<String>()»
            «FOR attribute : _interface.attributes»
                «{dispatcherDefinitionsList.add(generateAttributeDispatcherDefinitions(attribute, _interface, _accessor).toString());""}»
            «ENDFOR»
            «var counterMap = new HashMap<String, Integer>()»
            «var methodNumberMap = new HashMap<FMethod, Integer>()»
            «_interface.generateMethodDispatcherDeclarations(_interface, counterMap, methodNumberMap, _accessor)»
            «{counterMap = new HashMap<String, Integer>(); ""}»
            «{methodNumberMap = new HashMap<FMethod, Integer>(); ""}»
            «FOR method : _interface.methods»
                «{dispatcherDefinitionsList.add(generateMethodDispatcherDefinitions(method, _interface, _interface, _accessor, counterMap, methodNumberMap).toString());""}»
            «ENDFOR»
            «_interface.someipStubAdapterClassNameInternal»(
                const CommonAPI::SomeIP::Address &_address,
                const std::shared_ptr<CommonAPI::SomeIP::ProxyConnection> &_connection,
                const std::shared_ptr<CommonAPI::StubBase> &_stub):
                CommonAPI::SomeIP::StubAdapter(_address, _connection),
                «IF _interface.base === null»«_interface.someipStubAdapterHelperClassName»(
                    _address,
                    _connection,
                    std::dynamic_pointer_cast< «_interface.stubClassName»>(_stub)),
                «ENDIF»
                «IF _interface.base !== null»
                    «_interface.base.getTypeCollectionName(_interface)»SomeIPStubAdapterInternal<_Stub, _Stubs...>(_address, _connection, _stub),
                «ENDIF»
                get«_interface.elementName»InterfaceVersionStubDispatcher(&«_interface.stubClassName»::lockInterfaceVersionAttribute, &«_interface.stubClassName»::getInterfaceVersion, false, true)«IF dispatcherDefinitionsList.size > 0»,«ENDIF»
                «IF dispatcherDefinitionsList.size > 0»
                    «dispatcherDefinitionsList.map[it].join(',\n')»
                «ENDIF»
            {
                «_interface.generateAttributeDispatcherTableContent»
                «_interface.generateMethodDispatcherTableContent(counterMap, methodNumberMap)»
                «_interface.generateStubAttributeTableInitializer(_accessor)»
                «IF (!_interface.attributes.filter[isObservable()].empty)»
                    std::shared_ptr<CommonAPI::SomeIP::ClientId> itsClient = std::make_shared<CommonAPI::SomeIP::ClientId>(0xFFFF, 0xFFFFFFFF, 0xFFFFFFFF);

                «ENDIF»
                // Provided events/fields
                «FOR broadcast : _interface.broadcasts»
                    «IF !broadcast.isErrorType(_accessor)»
                        {
                            std::set<CommonAPI::SomeIP::eventgroup_id_t> itsEventGroups;
                            «FOR eventgroup : broadcast.getEventGroups(_accessor)»
                                itsEventGroups.insert(CommonAPI::SomeIP::eventgroup_id_t(«eventgroup»));
                            «ENDFOR»
                            «IF broadcast.selective»
                                CommonAPI::SomeIP::StubAdapter::registerEvent(«broadcast.getEventIdentifier(_accessor)», itsEventGroups, CommonAPI::SomeIP::event_type_e::ET_SELECTIVE_EVENT, «broadcast.getReliabilityType(_accessor)»);
                            «ELSE»
                                CommonAPI::SomeIP::StubAdapter::registerEvent(«broadcast.getEventIdentifier(_accessor)», itsEventGroups, CommonAPI::SomeIP::event_type_e::ET_EVENT, «broadcast.getReliabilityType(_accessor)»);
                            «ENDIF»
                        }
                    «ENDIF»
                «ENDFOR»
                «FOR attribute : _interface.attributes»
                    «IF attribute.observable»
                        if (_stub->hasElement(«_interface.getElementPosition(attribute)»)) {
                            std::set<CommonAPI::SomeIP::eventgroup_id_t> itsEventGroups;
                            «FOR eventgroup : attribute.getNotifierEventGroups(_accessor)»
                            itsEventGroups.insert(CommonAPI::SomeIP::eventgroup_id_t(«eventgroup»));
                            «ENDFOR»
                            CommonAPI::SomeIP::StubAdapter::registerEvent(«attribute.getNotifierIdentifier(_accessor)», itsEventGroups, CommonAPI::SomeIP::event_type_e::ET_FIELD, «attribute.getNotifierReliabilityType(_accessor)»);
                            «attribute.stubAdapterClassFireChangedMethodName»(std::dynamic_pointer_cast< «_interface.stubFullClassName»>(_stub)->«attribute.getMethodName»(itsClient));
                        }

                    «ENDIF»
                «ENDFOR»
            }

            // Register/Unregister event handlers for selective broadcasts
            void registerSelectiveEventHandlers();
            void unregisterSelectiveEventHandlers();

        «IF _interface.hasSelectiveBroadcasts || _interface.managedInterfaces.size > 0»
        private:
            «FOR broadcast: _interface.broadcasts»
                «IF broadcast.selective»
                    std::mutex «broadcast.className»Mutex_;
                    void «broadcast.className»Handler(CommonAPI::SomeIP::client_id_t _client, CommonAPI::SomeIP::uid_t _uid, CommonAPI::SomeIP::gid_t _gid, bool _subscribe, const CommonAPI::SomeIP::SubscriptionAcceptedHandler_t& _acceptedHandler);
                «ENDIF»
            «ENDFOR»

            «FOR managed: _interface.managedInterfaces»
                std::set<std::string> «managed.stubManagedSetName»;
            «ENDFOR»
        «ENDIF»
        };

        «FOR attribute : _interface.attributes.filter[isObservable()]»
            «FTypeGenerator::generateComments(attribute, false)»
            template <typename _Stub, typename... _Stubs>
            void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«attribute.stubAdapterClassFireChangedMethodName»(const «attribute.getTypeName(_interface, true)» &_value) {
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
                         «val String deployment = arg.getDeploymentRef(arg.array, broadcast, _interface, _accessor.getOverwriteAccessor(arg))»
                         «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                              CommonAPI::Deployable< «arg.getTypeName(arg, true)», «deploymentType»> deployed_«arg.name»(_«arg.name», «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
                         «ENDIF»
                    «ENDFOR»
                    if (client) {
                        CommonAPI::SomeIP::StubEventHelper<CommonAPI::SomeIP::SerializableArguments< «broadcast.outArgs.map[getDeployedTypeName(_interface, _accessor.getOverwriteAccessor(it))].join(', ')»>>
                          ::sendEvent(
                              client->getClientId(),
                              *this,
                              «broadcast.getEventIdentifier(_accessor)»,
                              «broadcast.getEndianess(_accessor)»«IF broadcast.outArgs.size > 0»,«ENDIF»
                              «broadcast.outArgs.map[getDeployedElementName(_interface, _accessor.getOverwriteAccessor(it))].join(', ')»
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
                void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> _client, bool &_success) {
                    bool ok = «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionRequestedMethodName»(_client);
                    if (ok) {
                        {
                            std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                            «broadcast.stubAdapterClassSubscriberListPropertyName»->insert(_client);
                        }
                        _success = true;
                    } else {
                        _success = false;
                    }
                }
                
                template <typename _Stub, typename... _Stubs>
                void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> _client) {
                    {
                        std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                        «broadcast.stubAdapterClassSubscriberListPropertyName»->erase(_client);
                    }
                }

                template <typename _Stub, typename... _Stubs>
                std::shared_ptr<CommonAPI::ClientIdList> const «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassSubscribersMethodName»() {
                    std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
                    return std::make_shared<CommonAPI::ClientIdList>(*«broadcast.stubAdapterClassSubscriberListPropertyName»);
                }

                template <typename _Stub, typename... _Stubs>
                void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.className»Handler(CommonAPI::SomeIP::client_id_t _client, CommonAPI::SomeIP::uid_t _uid, CommonAPI::SomeIP::gid_t _gid, bool _subscribe, const CommonAPI::SomeIP::SubscriptionAcceptedHandler_t& _acceptedHandler) {
                    std::shared_ptr<CommonAPI::SomeIP::ClientId> clientId = std::make_shared<CommonAPI::SomeIP::ClientId>(CommonAPI::SomeIP::ClientId(_client, _uid, _gid));
                    bool result = true;
                    if (_subscribe) {
                        «broadcast.subscribeSelectiveMethodName»(clientId, result);
                        if (result) {
                            _acceptedHandler(true);
                            «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::SUBSCRIBED);
                        } else {
                            _acceptedHandler(false);
                        }
                    } else {
                        «broadcast.unsubscribeSelectiveMethodName»(clientId);
                        «_interface.someipStubAdapterHelperClassName»::stub_->«broadcast.subscriptionChangedMethodName»(clientId, CommonAPI::SelectiveBroadcastSubscriptionEvent::UNSUBSCRIBED);
                        _acceptedHandler(true);
                    }
                }

            «ELSE»
                «IF !broadcast.isErrorType(_accessor)»
                    template <typename _Stub, typename... _Stubs>
                    void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.outArgs.map['const ' + getTypeName(_interface, true) + ' &_' + elementName].join(', ')») {
                        «FOR arg: broadcast.outArgs»
                            «val String deploymentType = arg.getDeploymentType(_interface, true)»
                            «val String deployment = arg.getDeploymentRef(arg.array, broadcast, _interface, _accessor.getOverwriteAccessor(arg))»
                            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
                                CommonAPI::Deployable< «arg.getTypeName(arg, true)», «deploymentType»> deployed_«arg.name»(_«arg.name», «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
                            «ENDIF»
                        «ENDFOR»
                        CommonAPI::SomeIP::StubEventHelper<CommonAPI::SomeIP::SerializableArguments< «broadcast.outArgs.map[getDeployedTypeName(_interface, _accessor.getOverwriteAccessor(it))].join(', ')»>>
                            ::sendEvent(
                                *this,
                                «broadcast.getEventIdentifier(_accessor)»,
                                «broadcast.getEndianess(_accessor)»«IF broadcast.outArgs.size > 0»,«ENDIF»
                                «broadcast.outArgs.map[getDeployedElementName(_interface, _accessor.getOverwriteAccessor(it))].join(', ')»
                        );
                    }

                «ENDIF»
            «ENDIF»
        «ENDFOR»

        template <typename _Stub, typename... _Stubs>
        void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::registerSelectiveEventHandlers() {
            «FOR broadcast : _interface.broadcasts»
                «IF broadcast.selective»
                    «broadcast.getStubAdapterClassSubscriberListPropertyName» = std::make_shared<CommonAPI::ClientIdList>();
                    CommonAPI::SomeIP::AsyncSubscriptionHandler_t «broadcast.className»SubscribeHandler =
                        std::bind(&«_interface.someipStubAdapterClassNameInternal»::«broadcast.className»Handler,
                        std::dynamic_pointer_cast<«_interface.someipStubAdapterClassNameInternal»>(this->shared_from_this()),
                        std::placeholders::_1, std::placeholders::_2, std::placeholders::_3, std::placeholders::_4, std::placeholders::_5);
                    CommonAPI::SomeIP::StubAdapter::connection_->registerSubscriptionHandler(CommonAPI::SomeIP::StubAdapter::getSomeIpAddress(), «broadcast.getEventGroups(_accessor).head», «broadcast.className»SubscribeHandler);

                «ENDIF»
            «ENDFOR»
        }
        
        template <typename _Stub, typename... _Stubs>
        void «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::unregisterSelectiveEventHandlers() {
            «FOR broadcast : _interface.broadcasts»
                «IF broadcast.selective»
                    CommonAPI::SomeIP::StubAdapter::connection_->unregisterSubscriptionHandler(CommonAPI::SomeIP::StubAdapter::getSomeIpAddress(), «broadcast.getEventGroups(_accessor).head»);
                «ENDIF»
            «ENDFOR»
        }

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
            bool «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...>::«managed.stubDeregisterManagedName»(const std::string &_instance) {
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
            : public «_interface.someipStubAdapterClassNameInternal»<_Stub, _Stubs...> {
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
                CommonAPI::SomeIP::GetAttributeStubDispatcher<
                    «_interface.stubFullClassName»,
                    «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                    «deploymentType»«ENDIF»
                > «a.someipGetStubDispatcherVariable»;

            «ENDIF»
            «IF !a.isReadonly»
                CommonAPI::SomeIP::Set«IF a.observable»Observable«ENDIF»AttributeStubDispatcher<
                    «_interface.stubFullClassName»,
                    «typeName»«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»,
                    «deploymentType»«ENDIF»
                > «a.someipSetStubDispatcherVariable»;

            «ENDIF»
        «ENDFOR»
    '''

    def private String generateMethodDispatcherDeclarations(FInterface _interface,
                                                            FInterface _container,
                                                            HashMap<String, Integer> _counters,
                                                            HashMap<FMethod, Integer> _methods,
                                                            PropertyAccessor _accessor) '''
        «val accessor = getSomeIpAccessor(_interface)»
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
                CommonAPI::SomeIP::MethodWithReplyStubDispatcher<
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
                CommonAPI::SomeIP::MethodStubDispatcher<
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

    def private generateAttributeDispatcherDefinitions(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) '''
        «val String getIdentifier = _attribute.getGetterIdentifier(_accessor)»
        «IF getIdentifier != "0x0"»
        «_attribute.someipGetStubDispatcherVariable»(
            &«_interface.stubFullClassName»::«_attribute.stubClassLockMethodName»,
            &«_interface.stubFullClassName»::«_attribute.stubClassGetMethodName»,
            «_attribute.getEndianess(_accessor)»,
            _stub->hasElement(«_interface.getElementPosition(_attribute)»)«IF _accessor.getOverwriteAccessor(_attribute).hasDeployment(_attribute)», «_attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor.getOverwriteAccessor(_attribute))»«ENDIF»)«IF !_attribute.isReadonly»,«ENDIF»
        «ENDIF»
        «IF !_attribute.isReadonly»
            «_attribute.someipSetStubDispatcherVariable»(
                &«_interface.stubFullClassName»::«_attribute.stubClassLockMethodName»,
                &«_interface.stubFullClassName»::«_attribute.stubClassGetMethodName»,
                &«_interface.stubRemoteEventClassName»::«_attribute.stubRemoteEventClassSetMethodName»,
                &«_interface.stubRemoteEventClassName»::«_attribute.stubRemoteEventClassChangedMethodName»,
                «IF _attribute.observable»&«_interface.stubAdapterClassName»::«_attribute.stubAdapterClassFireChangedMethodName»,«ENDIF»
                «_attribute.getEndianess(_accessor)»,
                _stub->hasElement(«_interface.getElementPosition(_attribute)»)«IF _accessor.getOverwriteAccessor(_attribute).hasDeployment(_attribute)»,
                «_attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor.getOverwriteAccessor(_attribute))»«ENDIF»)
        «ENDIF»
    '''

    def private generateMethodDispatcherDefinitions(FMethod _method, FInterface _interface, FInterface _thisInterface,
                                                    PropertyAccessor _accessor,
                                                    HashMap<String, Integer> counterMap,
                                                    HashMap<FMethod, Integer> methodnumberMap) '''
        «IF !_method.isFireAndForget»
            «var errorReplyTypes = new LinkedList()»
            «var errorReplyCallbacks = new LinkedList()»
            «FOR broadcast : _interface.broadcasts»
                «IF broadcast.isErrorType(_method, _accessor)»
                    «{errorReplyTypes.add(broadcast.errorReplyTypes(_method, _accessor));""}»
                    «{errorReplyCallbacks.add('std::bind(&' + _interface.someipStubAdapterClassNameInternal + '<_Stub, _Stubs...>::' +
                        broadcast.errorReplyCallbackName(_accessor) + ', this, ' + broadcast.errorReplyCallbackBindArgs(_accessor) + ')'
                    );""}»
                «ENDIF»
            «ENDFOR»
            «IF !(counterMap.containsKey(_method.someipStubDispatcherVariable))»
                «{counterMap.put(_method.someipStubDispatcherVariable, 0);  methodnumberMap.put(_method, 0);""}»
                «_method.someipStubDispatcherVariable»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»,
                    _stub->hasElement(«_interface.getElementPosition(_method)»),
                    «_method.getDeployments(_interface, _accessor, true, false)»,
                    «_method.getDeployments(_interface, _accessor, false, true)»«IF errorReplyCallbacks.size > 0»,«'\n' + errorReplyCallbacks.map[it].join(',\n')»«ENDIF»)
            «ELSE»
                «{counterMap.put(_method.someipStubDispatcherVariable, counterMap.get(_method.someipStubDispatcherVariable) + 1);  methodnumberMap.put(_method, counterMap.get(_method.someipStubDispatcherVariable));""}»
                «_method.someipStubDispatcherVariable»«Integer::toString(counterMap.get(_method.someipStubDispatcherVariable))»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»,
                    _stub->hasElement(«_interface.getElementPosition(_method)»),
                    «_method.getDeployments(_interface, _accessor, true, false)»,
                    «_method.getDeployments(_interface, _accessor, false, true)»«IF errorReplyCallbacks.size > 0»,«'\n' + errorReplyCallbacks.map[it].join(',\n')»«ENDIF»)
            «ENDIF»
            
        «ELSE»
            «IF !(counterMap.containsKey(_method.someipStubDispatcherVariable))»
                «{counterMap.put(_method.someipStubDispatcherVariable, 0); methodnumberMap.put(_method, 0);""}»
                «_method.someipStubDispatcherVariable»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»,
                    _stub->hasElement(«_interface.getElementPosition(_method)»),
                    «_method.getDeployments(_interface, _accessor, true, false)»)
            «ELSE»
                «{counterMap.put(_method.someipStubDispatcherVariable, counterMap.get(_method.someipStubDispatcherVariable) + 1);  methodnumberMap.put(_method, counterMap.get(_method.someipStubDispatcherVariable));""}»
                «_method.someipStubDispatcherVariable»«Integer::toString(counterMap.get(_method.someipStubDispatcherVariable))»(
                    &«_interface.stubClassName + "::" + _method.elementName»,
                    «_method.isLittleEndian(_accessor)»,
                    _stub->hasElement(«_interface.getElementPosition(_method)»),
                    «_method.getDeployments(_interface, _accessor, true, false)»)
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
        if (fInterface.base === null) {
            fInterface.stubFullClassName
        } else {
            fInterface.stubFullClassName + ", " + fInterface.base.interfaceHierarchy
        }
    }
    
    def private generateStubAdapterSource(FInterface _interface, PropertyAccessor _accessor, List<FDExtensionRoot> providers, IResource _modelid) '''
        «generateCommonApiSomeIPLicenseHeader()»
        #include <«_interface.someipStubAdapterHeaderPath»>
        #include <«_interface.headerPath»>

        «startInternalCompilation»

        #include <CommonAPI/SomeIP/AddressTranslator.hpp>

        «endInternalCompilation»

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
                «FOR i : ProviderUtils.getInstances(p).filter[target == _interface]»
                    CommonAPI::SomeIP::AddressTranslator::get()->insert(
                        "local:«_interface.fullyQualifiedNameWithVersion»:«providerAccessor.getInstanceId(i)»",
                         «_interface.getSomeIpServiceID», 0x«Integer.toHexString(
                            providerAccessor.getSomeIpInstanceID(i))», «_interface.version.major», «_interface.version.minor»);
                «ENDFOR»
            «ENDFOR»
            CommonAPI::SomeIP::Factory::get()->registerStubAdapterCreateMethod(
                "«_interface.fullyQualifiedNameWithVersion»",
                &create«_interface.someipStubAdapterClassName»);
        }

        INITIALIZER(register«_interface.someipStubAdapterClassName») {
            CommonAPI::SomeIP::Factory::get()->registerInterface(initialize«_interface.someipStubAdapterClassName»);
        }
        
        «_interface.model.generateNamespaceEndDeclaration»
        «_interface.generateVersionNamespaceEnd»
    '''

    def private String generateAttributeDispatcherTableContent(FInterface _interface) '''
        «val accessor = getSomeIpAccessor(_interface)»
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
    '''
    
    def private String generateMethodDispatcherTableContent(FInterface _interface, HashMap<String, Integer> _counters, HashMap<FMethod, Integer> _methods) '''
        «val accessor = getSomeIpAccessor(_interface)»
        «FOR method : _interface.methods»«FTypeGenerator::generateComments(method, false)»
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

    def private generateFireChangedMethodBody(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) '''
        «val String deploymentType = _attribute.getDeploymentType(_interface, true)»
        «val String deployment = _attribute.getDeploymentRef(_attribute.array, null, _interface, _accessor.getOverwriteAccessor(_attribute))»
        «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
            CommonAPI::Deployable< «_attribute.getTypeName(_interface, true)», «deploymentType»> deployedValue(_value, «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
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
            «IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»deployedValue«ELSE»_value«ENDIF»
        );
    '''

    def private generateStubAttributeTableInitializer(FInterface _interface, PropertyAccessor _accessor) '''
    '''

    def private generateErrorReplyCallback(FBroadcast _broadcast, FInterface _interface, FMethod _method, PropertyAccessor _accessor) '''
            
        void «_broadcast.errorReplyCallbackName(_accessor)»(«_broadcast.generateErrorReplyCallbackSignature(_method, _accessor)») {
            «IF _broadcast.errorArgs(_accessor).size > 1»
                auto args = std::make_tuple(
                    «_broadcast.errorArgs(_accessor).map[it.getDeployable(_interface, _accessor) + '(' + '_' + it.elementName + ', ' + getDeploymentRef(it.array, _broadcast, _interface, _accessor) + ')'].join(",\n")  + ");"»
            «ELSE»
                auto args = std::make_tuple();
            «ENDIF»
            (void)args;
            //sayHelloStubDispatcher.sendErrorReplyMessage(_call, «_broadcast.errorName(_accessor)», args);
        }
    '''
}
