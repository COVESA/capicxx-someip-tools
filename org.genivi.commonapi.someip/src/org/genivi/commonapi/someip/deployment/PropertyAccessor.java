/* Copyright (C) 2015-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.deployment;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.franca.core.franca.FArgument;
import org.franca.core.franca.FArrayType;
import org.franca.core.franca.FAttribute;
import org.franca.core.franca.FBroadcast;
import org.franca.core.franca.FEnumerationType;
import org.franca.core.franca.FField;
import org.franca.core.franca.FInterface;
import org.franca.core.franca.FMethod;
import org.franca.core.franca.FStructType;
import org.franca.core.franca.FUnionType;
import org.franca.deploymodel.core.FDeployedInterface;
import org.franca.deploymodel.ext.providers.FDeployedProvider;
import org.franca.deploymodel.core.FDeployedTypeCollection;
import org.franca.deploymodel.dsl.fDeploy.FDExtensionElement;
import org.genivi.commonapi.someip.Deployment;

public class PropertyAccessor extends org.genivi.commonapi.core.deployment.PropertyAccessor
{
	public enum SomeIpStringEncoding {
		utf8, utf16le, utf16be
	}

	Deployment.IDataPropertyAccessor someipDataAccessor_;
	Deployment.ProviderPropertyAccessor someipProvider_;

	PropertyAccessor parent_;
	String name_;

	public PropertyAccessor() {
		super();
		someipDataAccessor_ = null;
		someipProvider_ = null;
		parent_ = null;
		name_ = null;
	}

	public PropertyAccessor(FDeployedInterface _target) {
		super(_target);
		someipDataAccessor_ = new Deployment.InterfacePropertyAccessor(_target);
		someipProvider_ = null;
		parent_ = null;
		name_ = null;
	}

	public PropertyAccessor(FDeployedTypeCollection _target) {
		super(_target);
		someipDataAccessor_ = new Deployment.TypeCollectionPropertyAccessor(_target);
		someipProvider_ = null;
		parent_ = null;
		name_ = null;
	}

	public PropertyAccessor(FDeployedProvider _target) {
		super(_target);
		someipProvider_ = new Deployment.ProviderPropertyAccessor(_target);
		parent_ = null;
		someipDataAccessor_ = null;
		name_ = null;
	}

	public String getName() {
		if (name_ == null)
			return "";
		return name_;
	}

	private void setName(FField _element) {
		String containername = "";
		if (_element.eContainer() instanceof FStructType)
			containername = ((FStructType)(_element.eContainer())).getName() + "_";
		if (_element.eContainer() instanceof FUnionType)
			containername = ((FUnionType)(_element.eContainer())).getName() + "_";
		String parentname = parent_.name_;
		if (parentname != null) {
			name_ = parentname + containername + _element.getName() + "_";
		}
		else
			name_ = containername + _element.getName() + "_";
		return;
	}
	private void setName(FArgument _element) {
		if (_element.eContainer() instanceof FMethod)
			name_ = ((FMethod)(_element.eContainer())).getName() + "_" + _element.getName() + "_";
		if (_element.eContainer() instanceof FBroadcast)
			name_ = ((FBroadcast)(_element.eContainer())).getName() + "_" + _element.getName() + "_";
		return;
	}
	private void setName(FAttribute _element) {
		name_ = _element.getName() + "_";
		return;
	}
	private void setName(FArrayType _element) {
		if (someipDataAccessor_ != parent_.someipDataAccessor_) {
			String parentname = parent_.getName();
			if (parentname != null) {
				name_ = parentname + _element.getName() + "_";
			}
			else
				name_ = _element.getName() + "_";
		}
		else {
			name_ = parent_.getName();
		}
		return;
	}
	public PropertyAccessor(PropertyAccessor _parent, FField _element) {
		super();
		someipProvider_ = null;
		if (_parent.type_ != DeploymentType.PROVIDER && _parent != null && _parent.someipDataAccessor_ != null) {
			someipDataAccessor_ = _parent.someipDataAccessor_.getOverwriteAccessor(_element);
			type_ = DeploymentType.OVERWRITE;
		}
		else
			someipDataAccessor_ = null;

		parent_ = _parent;
		setName(_element);

	}
	public PropertyAccessor(PropertyAccessor _parent, FArrayType _element) {
		super();
		someipProvider_ = null;
		if (_parent.type_ != DeploymentType.PROVIDER && _parent != null && _parent.someipDataAccessor_ != null) {
			type_ = DeploymentType.OVERWRITE;
			someipDataAccessor_ = _parent.someipDataAccessor_.getOverwriteAccessor(_element);
		}
		else
			someipDataAccessor_ = null;
		parent_ = _parent;
		setName(_element);
	}
	public PropertyAccessor(PropertyAccessor _parent, FArgument _element) {
		type_ = DeploymentType.OVERWRITE;
		someipProvider_ = null;
		if (_parent.type_ == DeploymentType.INTERFACE) {
			Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) _parent.someipDataAccessor_;
			someipDataAccessor_ = ipa.getOverwriteAccessor(_element);
		}
		else
			someipDataAccessor_ = null;
		parent_ = _parent;
		setName(_element);
	}

	public PropertyAccessor(PropertyAccessor _parent, FAttribute _element) {
		type_ = DeploymentType.OVERWRITE;
		someipProvider_ = null;
		if (_parent.type_ == DeploymentType.INTERFACE) {
			Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) _parent.someipDataAccessor_;
			someipDataAccessor_ = ipa.getOverwriteAccessor(_element);
		}
		else
			someipDataAccessor_ = null;
		parent_ = _parent;
		setName(_element);
	}

	public PropertyAccessor getParent() {
		return parent_;
	}

	public PropertyAccessor getOverwriteAccessor(EObject _object) {
		if (_object instanceof FArgument)
			return new PropertyAccessor(this, (FArgument)_object);
		if (_object instanceof FAttribute)
			return new PropertyAccessor(this, (FAttribute)_object);
		if (_object instanceof FField)
			return new PropertyAccessor(this, (FField)_object);
		if (_object instanceof FArrayType)
			return new PropertyAccessor(this, (FArrayType)_object);
		return null;
	}

	public boolean isProperOverwrite() {
		// is proper overwrite if we are overwrite and none of my parents is the same accessor
		return (type_ == DeploymentType.OVERWRITE && !hasSameAccessor(someipDataAccessor_));
	}
	protected boolean hasSameAccessor(Deployment.IDataPropertyAccessor _accessor)
	{
		if (parent_ == null)
			return false;
		if (parent_.someipDataAccessor_ == _accessor)
			return true;
		return parent_.hasSameAccessor(_accessor);
	}

	public Integer getSomeIpServiceID (FInterface obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) someipDataAccessor_;
				return ipa.getSomeIpServiceID(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public List<Integer> getSomeIpEventGroups (FInterface obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) someipDataAccessor_;
				return ipa.getSomeIpEventGroups(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpGetterID (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) someipDataAccessor_;
				return ipa.getSomeIpGetterID(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Boolean getSomeIpGetterReliable (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) someipDataAccessor_;
				return ipa.getSomeIpAttributeReliable(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpSetterID (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) someipDataAccessor_;
				return ipa.getSomeIpSetterID(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Boolean getSomeIpSetterReliable (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) someipDataAccessor_;
				return ipa.getSomeIpAttributeReliable(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpNotifierID (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				Deployment.InterfacePropertyAccessor ipa = (Deployment.InterfacePropertyAccessor) someipDataAccessor_;
				return ipa.getSomeIpNotifierID(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Boolean getSomeIpNotifierReliable (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpAttributeReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public List<Integer> getSomeIpEventGroups (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				List<Integer> groups = ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpNotifierEventGroups(obj);
				if (groups == null) {
					groups = ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpEventGroups(obj);
				}
				return groups;
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public String getSomeIpEndianess (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return (((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpAttributeEndianess(obj)
						== Deployment.Enums.SomeIpAttributeEndianess.le ? "true" : "false");
		}
		catch (java.lang.NullPointerException e) {}
		return "false";
	}

	public Integer getSomeIpMethodID (FMethod obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpMethodID(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Boolean getSomeIpReliable (FMethod obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public String getSomeIpEndianess (FMethod obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return (((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpMethodEndianess(obj)
						== Deployment.Enums.SomeIpMethodEndianess.le ? "true" : "false");
		}
		catch (java.lang.NullPointerException e) {}
		return "false";
	}

	public Integer getSomeIpEventID (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpEventID(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Boolean getSomeIpReliable (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpReliable(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public List<Integer> getSomeIpEventGroups (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpEventGroups(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public String getSomeIpEndianess (FBroadcast obj) {
		try {
			if (type_ == DeploymentType.INTERFACE)
				return (((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpBroadcastEndianess(obj)
						== Deployment.Enums.SomeIpBroadcastEndianess.le ? "true" : "false");
		}
		catch (java.lang.NullPointerException e) {}
		return "false";
	}
	public EnumBackingType getEnumBackingType (FEnumerationType obj) {
		try {
			switch (type_) {
			case OVERWRITE:
				return parent_.getEnumBackingType(obj);
			default:
				return super.getEnumBackingType(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return EnumBackingType.UInt8;
	}
	public Integer getSomeIpArrayMinLength (FArrayType obj) {
		try {
			return someipDataAccessor_.getSomeIpArrayMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayMinLength (FField obj) {
		try {
			return someipDataAccessor_.getSomeIpArrayMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayMinLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArrayMinLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArrayMinLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayMinLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArrayMinLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArrayMinLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayMaxLength (FArrayType obj) {
		try {
			return someipDataAccessor_.getSomeIpArrayMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayMaxLength (FField obj) {
		try {
			return someipDataAccessor_.getSomeIpArrayMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayMaxLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArrayMaxLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArrayMaxLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayMaxLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArrayMaxLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArrayMaxLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayLengthWidth (FArrayType obj) {
		try {
			return someipDataAccessor_.getSomeIpArrayLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayLengthWidth (FField obj) {
		try {
			return someipDataAccessor_.getSomeIpArrayLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayLengthWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArrayLengthWidth(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArrayLengthWidth(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpArrayLengthWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArrayLengthWidth(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArrayLengthWidth(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpUnionLengthWidth (FUnionType obj) {
		try {
			return someipDataAccessor_.getSomeIpUnionLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpUnionTypeWidth (FUnionType obj) {
		try {
			return someipDataAccessor_.getSomeIpUnionTypeWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Boolean getSomeIpUnionDefaultOrder (FUnionType obj) {
		try {
			return someipDataAccessor_.getSomeIpUnionDefaultOrder(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpUnionMaxLength (FUnionType obj) {
		try {
			return someipDataAccessor_.getSomeIpUnionMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpStructLengthWidth (FStructType obj) {
		try {
			return someipDataAccessor_.getSomeIpStructLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpEnumWidth (FEnumerationType obj) {
		try {
			return someipDataAccessor_.getSomeIpEnumWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpEnumBitWidth (FEnumerationType obj) {
		try {
			return someipDataAccessor_.getSomeIpEnumBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpEnumInvalidValue (FEnumerationType obj) {
		try {
			return someipDataAccessor_.getSomeIpEnumInvalidValue(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpStringLength (EObject obj) {
		try {
			return someipDataAccessor_.getSomeIpStringLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpByteBufferMaxLength (EObject obj) {
		try {
			return someipDataAccessor_.getSomeIpByteBufferMaxLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpByteBufferMinLength (EObject obj) {
		try {
			return someipDataAccessor_.getSomeIpByteBufferMinLength(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpByteBufferLengthWidth(EObject obj) {
		try {
			return someipDataAccessor_.getSomeIpByteBufferLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpStringLengthWidth (EObject obj) {
		try {
			return someipDataAccessor_.getSomeIpStringLengthWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public SomeIpStringEncoding getSomeIpStringEncoding (EObject obj) {
		try {
			return from(someipDataAccessor_.getSomeIpStringEncoding(obj));
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpIntegerBitWidth (EObject obj) {
		try {
			return someipDataAccessor_.getSomeIpIntegerBitWidth(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}
	public Integer getSomeIpIntegerInvalidValue (EObject obj) {
		try {
			return someipDataAccessor_.getSomeIpIntegerInvalidValue(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgMapMinLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArgMapMinLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArgMapMinLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgMapMaxLength (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArgMapMaxLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArgMapMaxLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpArgMapLengthWidth (FArgument obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpArgMapLengthWidth(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpArgMapLengthWidth(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpAttrMapMinLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpAttrMapMinLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpAttrMapMinLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpAttrMapMaxLength (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpAttrMapMaxLength(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpAttrMapMaxLength(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpAttrMapLengthWidth (FAttribute obj) {
		try {
			if (type_ == DeploymentType.INTERFACE) {
				return ((Deployment.InterfacePropertyAccessor) someipDataAccessor_).getSomeIpAttrMapLengthWidth(obj);
			}
			if (type_ == DeploymentType.OVERWRITE) {
				return parent_.getSomeIpAttrMapLengthWidth(obj);
			}
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpInstanceID (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpInstanceID(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public String getSomeIpUnicastAddress (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpUnicastAddress(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpReliableUnicastPort (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpReliableUnicastPort(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public Integer getSomeIpUnreliableUnicastPort (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpUnreliableUnicastPort(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public List<String> getSomeIpMulticastAddresses (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpMulticastAddresses(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	public List<Integer> getSomeIpMulticastPorts (FDExtensionElement obj) {
		try {
			if (type_ == DeploymentType.PROVIDER)
				return someipProvider_.getSomeIpMulticastPorts(obj);
		}
		catch (java.lang.NullPointerException e) {}
		return null;
	}

	private SomeIpStringEncoding from(Deployment.Enums.SomeIpStringEncoding _source) {
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
