/* Copyright (C) 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.deployment;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.franca.core.franca.FArgument;
import org.franca.core.franca.FAttribute;
import org.franca.core.franca.FBroadcast;
import org.franca.core.franca.FEnumerationType;
import org.franca.core.franca.FField;
import org.franca.core.franca.FInterface;
import org.franca.core.franca.FMethod;
import org.franca.deploymodel.core.FDeployedInterface;
import org.franca.deploymodel.core.FDeployedProvider;
import org.franca.deploymodel.core.FDeployedTypeCollection;
import org.franca.deploymodel.dsl.fDeploy.FDInterfaceInstance;
import org.genivi.commonapi.someip.DeploymentInterfacePropertyAccessor;
import org.genivi.commonapi.someip.DeploymentInterfacePropertyAccessor.SomeIpAttributeEndianess;
import org.genivi.commonapi.someip.DeploymentInterfacePropertyAccessor.SomeIpBroadcastEndianess;
import org.genivi.commonapi.someip.DeploymentInterfacePropertyAccessor.SomeIpMethodEndianess;
import org.genivi.commonapi.someip.DeploymentProviderPropertyAccessor;
import org.genivi.commonapi.someip.DeploymentTypeCollectionPropertyAccessor;

public class PropertyAccessor extends org.genivi.commonapi.core.deployment.PropertyAccessor
{
	public enum SomeIpStringEncoding {
		utf8, utf16le, utf16be
	}
	
	DeploymentInterfacePropertyAccessor someipInterface_;
	DeploymentTypeCollectionPropertyAccessor someipTypeCollection_;
	DeploymentProviderPropertyAccessor someipProvider_;

	public PropertyAccessor() {
		super();
		someipInterface_ = null;
		someipTypeCollection_ = null;
		someipProvider_ = null;
	}

	public PropertyAccessor(FDeployedInterface _target) {
		super(_target);
		someipInterface_ = new DeploymentInterfacePropertyAccessor(_target);
		someipTypeCollection_ = null;
		someipProvider_ = null;
	}

	public PropertyAccessor(FDeployedTypeCollection _target) {
		super(_target);
		someipInterface_ = null;
		someipTypeCollection_ = new DeploymentTypeCollectionPropertyAccessor(_target);
		someipProvider_ = null;
	}

	public PropertyAccessor(FDeployedProvider _target) {
		super(_target);
		someipInterface_ = null;
		someipTypeCollection_ = null;
		someipProvider_ = new DeploymentProviderPropertyAccessor(_target);
	}

	public Integer getSomeIpServiceID (FInterface obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpServiceID(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public List<Integer> getSomeIpEventGroups (FInterface obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpEventGroups(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpGetterID (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpGetterID(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Boolean getSomeIpGetterReliable (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpGetterReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpGetterPriority (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpGetterPriority(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Integer getSomeIpSetterID (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpSetterID(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Boolean getSomeIpSetterReliable (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpSetterReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Integer getSomeIpSetterPriority (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpSetterPriority(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Integer getSomeIpNotifierID (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpNotifierID(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Boolean getSomeIpNotifierReliable (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpNotifierReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpNotifierPriority (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpNotifierPriority(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Boolean getSomeIpNotifierMulticast (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpNotifierMulticast(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public List<Integer> getSomeIpEventGroups (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpEventGroups(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public String getSomeIpEndianess (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return (someipInterface_.getSomeIpAttributeEndianess(obj) 
							== SomeIpAttributeEndianess.le ? "true" : "false");
		}
		catch (java.lang.NullPointerException e) {}
		return "false";
	}
	
	public Integer getSomeIpMethodID (FMethod obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return someipInterface_.getSomeIpMethodID(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Boolean getSomeIpReliable (FMethod obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public String getSomeIpEndianess (FMethod obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return (someipInterface_.getSomeIpMethodEndianess(obj) 
							== SomeIpMethodEndianess.le ? "true" : "false");
		}
		catch (java.lang.NullPointerException e) {}
		return "false";		
	}
	
	public Integer getSomeIpPriority (FMethod obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpPriority(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Integer getSomeIpEventID (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpEventID(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Boolean getSomeIpReliable (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Integer getSomeIpPriority (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpPriority(obj);
		}
		catch (java.lang.NullPointerException e) {}		
		return null;
	}
	
	public Boolean getSomeIpMulticast (FBroadcast obj) {
		try {		
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpMulticast(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public List<Integer> getSomeIpEventGroups (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpEventGroups(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getSomeIpEndianess (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return (someipInterface_.getSomeIpBroadcastEndianess(obj) 
							== SomeIpBroadcastEndianess.le ? "true" : "false");
		}
		catch (java.lang.NullPointerException e) {}
		return "false";
	}	
	
	public Integer getSomeIpArrayMinLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArrayMinLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpArrayMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpArrayMaxLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArrayMaxLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpArrayMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpArrayLengthWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArrayLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpArrayLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionLengthWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionTypeWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionTypeWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionTypeWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Boolean getSomeIpUnionDefaultOrder (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionDefaultOrder(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionDefaultOrder(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpUnionMaxLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionMaxLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpStructLengthWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpEnumWidth (FEnumerationType obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpEnumWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpEnumWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpEnumBitWidth (FEnumerationType obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpEnumBitWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpEnumBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpEnumInvalidValue (FEnumerationType obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpEnumInvalidValue(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpEnumInvalidValue(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpStringLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStringLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStringLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpByteBufferMaxLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpByteBufferMaxLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpByteBufferMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpByteBufferMinLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpByteBufferMinLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpByteBufferMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpStringLengthWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStringLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStringLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public SomeIpStringEncoding getSomeIpStringEncoding (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return from(someipInterface_.getSomeIpStringEncoding(obj));
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return from(someipTypeCollection_.getSomeIpStringEncoding(obj));
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpAttrArrayMinLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrArrayMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpAttrArrayMaxLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrArrayMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	}
	
	public Integer getSomeIpAttrArrayLengthWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrArrayLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpAttrUnionLengthWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrUnionLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpAttrUnionTypeWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrUnionTypeWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Boolean getSomeIpAttrUnionDefaultOrder (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrUnionDefaultOrder(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpAttrUnionMaxLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrUnionMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpAttrStructLengthWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrStructLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpAttrEnumWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrEnumWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpAttrEnumBitWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrEnumBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpAttrIntegerBitWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrIntegerBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpArgArrayMinLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgArrayMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpArgArrayMaxLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgArrayMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpArgArrayLengthWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgArrayLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpArgMapMinLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgMapMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgMapMaxLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgMapMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgMapLengthWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgMapLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpAttrMapMinLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrMapMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpAttrMapMaxLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrMapMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpAttrMapLengthWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpAttrMapLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgUnionLengthWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgUnionLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpArgUnionTypeWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgUnionTypeWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Boolean getSomeIpArgUnionDefaultOrder (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgUnionDefaultOrder(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpArgUnionMaxLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgUnionMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpArgStructLengthWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgStructLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;	
	}
	
	public Integer getSomeIpArgEnumWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgEnumWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgEnumBitWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgEnumBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgEnumInvalidValue(FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgEnumInvalidValue(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;		
	}
	
	public Integer getSomeIpArgIntegerBitWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgIntegerBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpArgIntegerInvalidValue(FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpArgIntegerInvalidValue(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;		
	}
	
	public Integer getSomeIpStructArrayMinLength (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructArrayMinLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructArrayMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructArrayMaxLength (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructArrayMaxLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructArrayMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructArrayLengthWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructArrayLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructArrayLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructUnionLengthWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructUnionLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructUnionLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructUnionTypeWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructUnionTypeWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructUnionTypeWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Boolean getSomeIpStructUnionDefaultOrder (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructUnionDefaultOrder(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructUnionDefaultOrder(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructUnionMaxLength (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructUnionMaxLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructUnionMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructStructLengthWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructStructLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructStructLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructEnumWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructEnumWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructEnumWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpStructEnumBitWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructEnumBitWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructEnumBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructEnumInvalidValue (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructEnumInvalidValue(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructEnumInvalidValue(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpStructIntegerBitWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructIntegerBitWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructIntegerBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpStructIntegerInvalidValue (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpStructIntegerInvalidValue(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpStructIntegerInvalidValue(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionArrayMinLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionArrayMinLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionArrayMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionArrayMaxLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionArrayMaxLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionArrayMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionArrayLengthWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionArrayLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionArrayLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionUnionLengthWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionUnionLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionUnionLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionUnionTypeWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionUnionTypeWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionUnionTypeWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Boolean getSomeIpUnionUnionDefaultOrder (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionUnionDefaultOrder(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionUnionDefaultOrder(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionUnionMaxLength (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionUnionMaxLength(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionUnionMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionStructLengthWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionStructLengthWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionStructLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionEnumWidth (EObject obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionEnumWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionEnumWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpUnionEnumBitWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionEnumBitWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionEnumBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpUnionIntegerBitWidth (FField obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return someipInterface_.getSomeIpUnionIntegerBitWidth(obj);
			if (type_ == DeploymentType.TYPE_COLLECTION)
				return someipTypeCollection_.getSomeIpUnionIntegerBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpInstanceID (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpInstanceID(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public String getSomeIpUnicastAddress (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpUnicastAddress(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public Integer getSomeIpReliableUnicastPort (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpReliableUnicastPort(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpUnreliableUnicastPort (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpUnreliableUnicastPort(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public List<String> getSomeIpMulticastAddresses (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpMulticastAddresses(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	
	public List<Integer> getSomeIpMulticastPorts (FDInterfaceInstance obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpMulticastPorts(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	private SomeIpStringEncoding from(DeploymentInterfacePropertyAccessor.SomeIpStringEncoding _source) {
		if (_source != null) {
			switch (_source) {
			case utf16be:
				return SomeIpStringEncoding.utf16be;
			case utf16le:
				return SomeIpStringEncoding.utf16le;
			default:
				return SomeIpStringEncoding.utf8;
			}
		} 
		return SomeIpStringEncoding.utf8;
	}
	
	private SomeIpStringEncoding from(DeploymentTypeCollectionPropertyAccessor.SomeIpStringEncoding _source) {
		if (_source != null) {
			switch (_source) {
			case utf16be:
				return SomeIpStringEncoding.utf16be;
			case utf16le:
				return SomeIpStringEncoding.utf16le;
			default:
				return SomeIpStringEncoding.utf8;
			}
		}
		return SomeIpStringEncoding.utf8;
	}
}
