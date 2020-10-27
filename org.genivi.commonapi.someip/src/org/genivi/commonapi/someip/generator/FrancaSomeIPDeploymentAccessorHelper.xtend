/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import org.eclipse.emf.ecore.EObject
import org.franca.core.franca.FArgument
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FField
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FTypedElement
import org.franca.core.franca.FUnionType
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.franca.core.franca.FTypeCollection
import javax.inject.Inject
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMapType
import org.franca.core.franca.FIntegerInterval

class FrancaSomeIPDeploymentAccessorHelper {

    @Inject extension FrancaSomeIPGeneratorExtensions

    public static Integer SOMEIP_DEFAULT_MIN_LENGTH = 0
    public static Integer SOMEIP_DEFAULT_MAX_LENGTH = 0
    public static Integer SOMEIP_DEFAULT_LENGTH_WIDTH = 4
    public static Integer SOMEIP_DEFAULT_STRING_LENGTH = 0
    public static Integer SOMEIP_DEFAULT_ENUM_LENGTH_WIDTH = 1

    public static Integer SOMEIP_DEFAULT_STRUCT_LENGTH_WIDTH = 0

    public static Integer SOMEIP_DEFAULT_UNION_TYPE_WIDTH = 4
    public static boolean SOMEIP_DEFAULT_UNION_DEFAULT_ORDER = true

    public static Integer SOMEIP_DEFAULT_ENUM_WIDTH = 1

    public static PropertyAccessor.SomeIpStringEncoding SOMEIP_DEFAULT_STRING_ENCODING
        = PropertyAccessor.SomeIpStringEncoding.utf8

    // Helper methods to get a specific deployment value
    def Integer getSomeIpArrayMinLengthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            var Integer minLength = _accessor.getSomeIpArrayMinLength(_obj)
            if (minLength === null && _obj.type.derived !== null)
                minLength = _accessor.getSomeIpArrayMinLengthHelper(_obj.type.derived)
            return minLength
        }

        if (_obj instanceof FArgument) {
            var Integer minLength = _accessor.getSomeIpArrayMinLength(_obj)
            if (minLength === null && _obj.type.derived !== null)
                minLength = _accessor.getSomeIpArrayMinLengthHelper(_obj.type.derived)
            return minLength
        }

        if (_obj instanceof FField) {
            var Integer minLength = _accessor.getSomeIpArrayMinLength(_obj)
            return minLength
        }

        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FArrayType) {
                    return _accessor.getSomeIpArrayMinLength(_obj.actualType.derived as FArrayType)
                }
            } else {
                return SOMEIP_DEFAULT_MIN_LENGTH
            }
        }
        if (_obj instanceof FArrayType)
            return _accessor.getSomeIpArrayMinLength(_obj)
        return SOMEIP_DEFAULT_MIN_LENGTH
    }

    def Integer getSomeIpArrayMaxLengthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            var Integer maxLength = _accessor.getSomeIpArrayMaxLength(_obj)
            if (maxLength === null && _obj.type.derived !== null)
                maxLength = _accessor.getSomeIpArrayMaxLengthHelper(_obj.type.derived)
            return maxLength
        }

        if (_obj instanceof FArgument) {
            var Integer maxLength = _accessor.getSomeIpArrayMaxLength(_obj)
            if (maxLength === null && _obj.type.derived !== null)
                  maxLength = _accessor.getSomeIpArrayMaxLengthHelper(_obj.type.derived)
            return maxLength
        }

        if (_obj instanceof FField) {
            var Integer maxLength = _accessor.getSomeIpArrayMaxLength(_obj)
            return maxLength
        }

        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FArrayType) {
                    return _accessor.getSomeIpArrayMaxLength(_obj.actualType.derived as FArrayType)
                }
            } else {
                return SOMEIP_DEFAULT_MAX_LENGTH
            }
        }
        if (_obj instanceof FArrayType)
            return _accessor.getSomeIpArrayMaxLength(_obj)
        return SOMEIP_DEFAULT_MAX_LENGTH
    }

    def Integer getSomeIpArrayLengthWidthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            var Integer lengthWidth = _accessor.getSomeIpArrayLengthWidth(_obj)
            if (lengthWidth === null && _obj.type.derived !== null)
                lengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_obj.type.derived)
            return lengthWidth
        }

        if (_obj instanceof FArgument) {
            var Integer lengthWidth = _accessor.getSomeIpArrayLengthWidth(_obj)
            if (lengthWidth === null && _obj.type.derived !== null)
                lengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_obj.type.derived)
            return lengthWidth
        }

        if (_obj instanceof FField) {
            var Integer lengthWidth = _accessor.getSomeIpArrayLengthWidth(_obj)
            return lengthWidth
        }

        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FArrayType) {
                    return _accessor.getSomeIpArrayLengthWidth(_obj.actualType.derived as FArrayType)
                }
            } else {
                return SOMEIP_DEFAULT_LENGTH_WIDTH
            }
        }
        if (_obj instanceof FArrayType)
            return _accessor.getSomeIpArrayLengthWidth(_obj)
        return SOMEIP_DEFAULT_LENGTH_WIDTH
    }

    def Integer getSomeIpMapMinLengthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            var Integer minLength = _accessor.getSomeIpAttrMapMinLength(_obj)
            if (minLength === null && _obj.type.derived !== null)
                minLength = _accessor.getSomeIpMapMinLengthHelper(_obj.type.derived)
            return minLength
        }

        if (_obj instanceof FArgument) {
            var Integer minLength = _accessor.getSomeIpArgMapMinLength(_obj)
            if (minLength === null && _obj.type.derived !== null)
                minLength = _accessor.getSomeIpMapMinLengthHelper(_obj.type.derived)
            return minLength
        }

        return SOMEIP_DEFAULT_MIN_LENGTH
    }

    def Integer getSomeIpMapMaxLengthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            var Integer maxLength = _accessor.getSomeIpAttrMapMaxLength(_obj)
            if (maxLength === null && _obj.type.derived !== null)
                maxLength = _accessor.getSomeIpMapMaxLengthHelper(_obj.type.derived)
            return maxLength
        }

        if (_obj instanceof FArgument) {
            var Integer maxLength = _accessor.getSomeIpArgMapMaxLength(_obj)
            if (maxLength === null && _obj.type.derived !== null)
                maxLength = _accessor.getSomeIpMapMaxLengthHelper(_obj.type.derived)
            return maxLength
        }

        return SOMEIP_DEFAULT_MAX_LENGTH
    }

    def Integer getSomeIpMapLengthWidthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            var Integer lengthWidth = _accessor.getSomeIpAttrMapLengthWidth(_obj)
            if (lengthWidth === null && _obj.type.derived !== null)
                lengthWidth = _accessor.getSomeIpMapLengthWidthHelper(_obj.type.derived)
            return lengthWidth
        }

        if (_obj instanceof FArgument) {
            var Integer lengthWidth = _accessor.getSomeIpArgMapLengthWidth(_obj)
            if (lengthWidth === null && _obj.type.derived !== null)
                lengthWidth = _accessor.getSomeIpMapLengthWidthHelper(_obj.type.derived)
            return lengthWidth
        }

        return SOMEIP_DEFAULT_LENGTH_WIDTH
    }

    def Integer getSomeIpUnionLengthWidthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            return _accessor.getSomeIpUnionLengthWidthHelper(_obj.type.derived)
        }

        if (_obj instanceof FArgument) {
            return _accessor.getSomeIpUnionLengthWidthHelper(_obj.type.derived)
        }
        if (_obj instanceof FField) {
            return _accessor.getSomeIpUnionLengthWidthHelper(_obj.type.derived)
        }
        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FUnionType) {
                    return _accessor.getSomeIpUnionLengthWidth(_obj.actualType.derived as FUnionType)
                }
              } else {
                return SOMEIP_DEFAULT_LENGTH_WIDTH
            }
        }
        if (_obj instanceof FUnionType)
            return _accessor.getSomeIpUnionLengthWidth(_obj)
        return SOMEIP_DEFAULT_LENGTH_WIDTH
    }

    def Integer getSomeIpUnionTypeWidthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            return _accessor.getSomeIpUnionTypeWidthHelper(_obj.type.derived)
        }

        if (_obj instanceof FArgument) {
            return _accessor.getSomeIpUnionTypeWidthHelper(_obj.type.derived)
        }
        if (_obj instanceof FField) {
            return _accessor.getSomeIpUnionTypeWidthHelper(_obj.type.derived)
        }
        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FUnionType) {
                    return _accessor.getSomeIpUnionTypeWidth(_obj.actualType.derived as FUnionType)
                }
            } else {
                return SOMEIP_DEFAULT_UNION_TYPE_WIDTH
            }
        }
        if (_obj instanceof FUnionType)
            return _accessor.getSomeIpUnionTypeWidth(_obj)
        return SOMEIP_DEFAULT_UNION_TYPE_WIDTH
    }

    def Boolean getSomeIpUnionDefaultOrderHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            return _accessor.getSomeIpUnionDefaultOrderHelper(_obj.type.derived)
        }

        if (_obj instanceof FArgument) {
            return _accessor.getSomeIpUnionDefaultOrderHelper(_obj.type.derived)
        }
        if (_obj instanceof FField) {
            return _accessor.getSomeIpUnionDefaultOrderHelper(_obj.type.derived)
        }
        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FUnionType) {
                    return _accessor.getSomeIpUnionDefaultOrder(_obj.actualType.derived as FUnionType)
                }
            } else {
                return SOMEIP_DEFAULT_UNION_DEFAULT_ORDER
            }
        }
        if (_obj instanceof FUnionType)
            return _accessor.getSomeIpUnionDefaultOrder(_obj)
        return SOMEIP_DEFAULT_UNION_DEFAULT_ORDER
    }

    def Integer getSomeIpUnionMaxLengthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            return _accessor.getSomeIpUnionMaxLengthHelper(_obj.type.derived)
        }

        if (_obj instanceof FArgument) {
            return _accessor.getSomeIpUnionMaxLengthHelper(_obj.type.derived)
        }
        if (_obj instanceof FField) {
            return _accessor.getSomeIpUnionMaxLengthHelper(_obj.type.derived)
        }
        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FUnionType) {
                    return _accessor.getSomeIpUnionMaxLength(_obj.actualType.derived as FUnionType)
                }
            } else {
                return SOMEIP_DEFAULT_MAX_LENGTH
            }
        }
        if (_obj instanceof FUnionType)
            return _accessor.getSomeIpUnionMaxLength(_obj)
        return SOMEIP_DEFAULT_MAX_LENGTH
    }

    def Integer getSomeIpStructLengthWidthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj instanceof FAttribute) {
            return _accessor.getSomeIpStructLengthWidthHelper(_obj.type.derived)
        }

        if (_obj instanceof FArgument) {
            return _accessor.getSomeIpStructLengthWidthHelper(_obj.type.derived)
        }
        if (_obj instanceof FField) {
            return _accessor.getSomeIpStructLengthWidthHelper(_obj.type.derived)
        }
        if (_obj instanceof FTypeDef) {
            if (_obj.actualType.derived !== null) {
                if (_obj.actualType.derived instanceof FStructType) {
                    return _accessor.getSomeIpStructLengthWidth(_obj.actualType.derived as FStructType)
                }
            } else {
                return SOMEIP_DEFAULT_STRUCT_LENGTH_WIDTH
            }
        }
        if (_obj instanceof FStructType)
            return _accessor.getSomeIpStructLengthWidth(_obj)
        return SOMEIP_DEFAULT_STRUCT_LENGTH_WIDTH
    }

    def Integer getSomeIpEnumWidthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj !== null) {
            if (_obj instanceof FEnumerationType) {
                var Integer enumWidth = _accessor.getSomeIpEnumWidth(_obj)
                var Integer enumBaseWidth = null
                if (_obj.base !== null) {
                    val itsBaseAccessor = getSomeIpAccessor(_obj.base.eContainer as FTypeCollection)
                    if (itsBaseAccessor !== null)
                        enumBaseWidth = itsBaseAccessor.getSomeIpEnumWidthHelper(_obj.base)
                }
                return (enumBaseWidth !== null && enumBaseWidth > enumWidth ? enumBaseWidth : enumWidth)
            }

            if (_obj instanceof FTypeDef) {
                if (_obj.actualType.derived !== null) {
                    val FType derived = _obj.actualType.derived
                    if (derived instanceof FEnumerationType) {
                        return _accessor.getSomeIpEnumWidthHelper(derived)
                    }
                }
                return SOMEIP_DEFAULT_ENUM_WIDTH
            }
        }
        return null
    }

    def Integer getSomeIpEnumBitWidthHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj !== null) {
            if (_obj instanceof FEnumerationType) {
                var Integer enumBitWidth = _accessor.getSomeIpEnumBitWidth(_obj)
                var Integer enumBaseBitWidth = null
                if (_obj.base !== null) {
                    val itsBaseAccessor = getSomeIpAccessor(_obj.base.eContainer as FTypeCollection)
                    if (itsBaseAccessor !== null)
                        enumBaseBitWidth = itsBaseAccessor.getSomeIpEnumBitWidthHelper(_obj.base)
                }
                return (enumBaseBitWidth !== null && enumBaseBitWidth > enumBitWidth ? enumBaseBitWidth : enumBitWidth)
            }

            if (_obj instanceof FTypeDef) {
                if (_obj.actualType.derived !== null) {
                    val FType derived = _obj.actualType.derived
                    if (derived instanceof FEnumerationType) {
                        return _accessor.getSomeIpEnumBitWidthHelper(derived)
                    }
                }
            }
        }
        return null
    }

    def Integer getSomeIpEnumInvalidValueHelper(PropertyAccessor _accessor, EObject _obj) {
        if (_obj !== null) {
            if (_obj instanceof FEnumerationType) {
                var Integer invalidValue = _accessor.getSomeIpEnumInvalidValue(_obj)
                if (invalidValue === null)
                    invalidValue = _accessor.getSomeIpEnumInvalidValueHelper(_obj.base)
                return invalidValue
            }
            if (_obj instanceof FTypeDef) {
                if (_obj.actualType.derived !== null) {
                    val FType derived = _obj.actualType.derived
                    if (derived instanceof FEnumerationType) {
                        return _accessor.getSomeIpEnumInvalidValueHelper(derived)
                    }
                }
            }
    }
        return null
    }

    def Integer getSomeIpIntegerBitWidthHelper(PropertyAccessor _accessor, EObject _obj) {
         return _accessor.getSomeIpIntegerBitWidth(_obj)
    }

    def Integer getSomeIpIntegerInvalidValueHelper(PropertyAccessor _accessor, EObject _obj) {
        return _accessor.getSomeIpIntegerInvalidValue(_obj)
    }

    def PropertyAccessor getSpecificAccessor(EObject _object) {
        var container = _object.eContainer
        while (container !== null) {
            if(container instanceof FInterface) {
                return getSomeIpAccessor(container)
            }
            if(container instanceof FTypeCollection) {
                return getSomeIpAccessor(container)
            }
            container = container.eContainer
        }
        return null
    }


    // Helper to check whether the deployment differs from the default deployment
    def boolean hasSomeIpArrayMinLength(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultMinLength = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultMinLength = _accessor.getSomeIpArrayMinLengthHelper(_object.type.derived)
                    if (defaultMinLength === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if (newAccessor !== null)
                            defaultMinLength = newAccessor.getSomeIpArrayMinLengthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultMinLength === null)
            defaultMinLength = SOMEIP_DEFAULT_MIN_LENGTH

        var Integer minLength = _accessor.getSomeIpArrayMinLengthHelper(_object)
        if(minLength !== null && minLength != defaultMinLength) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            minLength = newAccessor.getSomeIpArrayMinLengthHelper(_object)
            return minLength !== null && minLength != defaultMinLength
        }
        return false
    }

    def boolean hasSomeIpArrayMaxLength(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultMaxLength = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultMaxLength = _accessor.getSomeIpArrayMaxLengthHelper(_object.type.derived)
                    if (defaultMaxLength === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultMaxLength = newAccessor.getSomeIpArrayMaxLengthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultMaxLength === null)
            defaultMaxLength = SOMEIP_DEFAULT_MAX_LENGTH

        var Integer maxLength = _accessor.getSomeIpArrayMaxLengthHelper(_object)
        if(maxLength !== null && maxLength != defaultMaxLength) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            maxLength = newAccessor.getSomeIpArrayMaxLengthHelper(_object)
            return maxLength !== null && maxLength != defaultMaxLength
        }
        return false
    }

    def boolean hasSomeIpArrayLengthWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultLengthWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultLengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_object.type.derived)
                    if (defaultLengthWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultLengthWidth = newAccessor.getSomeIpArrayLengthWidthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultLengthWidth === null)
            defaultLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH

        var Integer lengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_object)
        if(lengthWidth !== null && lengthWidth != defaultLengthWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            lengthWidth = newAccessor.getSomeIpArrayLengthWidthHelper(_object)
            return lengthWidth !== null && lengthWidth != defaultLengthWidth
        }
        return false
    }

    def boolean hasSomeIpByteBufferMinLength(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultMinWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultMinWidth = _accessor.getSomeIpByteBufferMinLength(_object.type.derived)
                    if (defaultMinWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultMinWidth = newAccessor.getSomeIpByteBufferMinLength(_object.type.derived)
                    }
                }
            }
        }
        if (defaultMinWidth === null)
            defaultMinWidth = SOMEIP_DEFAULT_MIN_LENGTH

        var Integer length = _accessor.getSomeIpByteBufferMinLength(_object)
        if(length !== null && length != defaultMinWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            length = newAccessor.getSomeIpByteBufferMinLength(_object)
            return length !== null && length != defaultMinWidth
        }
        return false
    }

    def boolean hasSomeIpByteBufferMaxLength(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultMaxWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultMaxWidth = _accessor.getSomeIpByteBufferMaxLength(_object.type.derived)
                    if (defaultMaxWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultMaxWidth = newAccessor.getSomeIpByteBufferMaxLength(_object.type.derived)
                    }
                }
            }
        }
        if (defaultMaxWidth === null)
            defaultMaxWidth = SOMEIP_DEFAULT_MAX_LENGTH

        var Integer length = _accessor.getSomeIpByteBufferMaxLength(_object)
        if(length !== null && length != defaultMaxWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            length = newAccessor.getSomeIpByteBufferMaxLength(_object)
            return length !== null && length != defaultMaxWidth
        }
        return false
    }

    def boolean hasSomeIpByteBufferLengthWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultLengthWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultLengthWidth = _accessor.getSomeIpByteBufferLengthWidth(_object.type.derived)
                    if (defaultLengthWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultLengthWidth = newAccessor.getSomeIpByteBufferLengthWidth(_object.type.derived)
                    }
                }
            }
        }
        if (defaultLengthWidth === null)
            defaultLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH

        var Integer length = _accessor.getSomeIpByteBufferLengthWidth(_object)
        if (length !== null && length != defaultLengthWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if (newAccessor !== null) {
            length = newAccessor.getSomeIpByteBufferMaxLength(_object)
            return length !== null && length != defaultLengthWidth
        }
        return false
    }

    def boolean isDefaultWidth(int _width) {
        return (_width == 0 || _width == 8 || _width == 16 || _width == 32 || _width == 64)
    }

    def boolean hasSomeIpIntegerBitWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer width = _accessor.getSomeIpIntegerBitWidthHelper(_object);
        if (width !== null && !isDefaultWidth(width.intValue()))
            return true

        var newAccessor = getSpecificAccessor(_object)
        if (newAccessor !== null) {
            width = newAccessor.getSomeIpIntegerBitWidthHelper(_object)
            if (width !== null && !isDefaultWidth(width.intValue()))
                return true
        }

        return false
    }

    def boolean hasSomeIpIntegerInvalidValue(PropertyAccessor _accessor, EObject _object) {
        var Integer invalidValue = _accessor.getSomeIpIntegerInvalidValueHelper(_object)
        if (invalidValue !== null)
            return true

        var newAccessor = getSpecificAccessor(_object)
        if (newAccessor !== null) {
            invalidValue = newAccessor.getSomeIpIntegerInvalidValueHelper(_object)
            if (invalidValue !== null)
                return true
        }

        return false
    }

    def boolean hasSomeIpStringLength(PropertyAccessor _accessor, EObject _object) {
        var Integer length = _accessor.getSomeIpStringLength(_object)
        if(length !== null && length != SOMEIP_DEFAULT_MIN_LENGTH) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            length = newAccessor.getSomeIpStringLength(_object)
            return length !== null && length != SOMEIP_DEFAULT_MIN_LENGTH
        }
        return false
    }

    def boolean hasSomeIpStringLengthWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer lengthWidth = _accessor.getSomeIpStringLengthWidth(_object)
        if(lengthWidth !== null && lengthWidth != SOMEIP_DEFAULT_LENGTH_WIDTH) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            lengthWidth = newAccessor.getSomeIpStringLengthWidth(_object)
            return lengthWidth !== null && lengthWidth != SOMEIP_DEFAULT_LENGTH_WIDTH
        }
        return false
    }


    def boolean hasSomeIpStructLengthWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultLengthWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultLengthWidth = _accessor.getSomeIpStructLengthWidthHelper(_object.type.derived)
                    if (defaultLengthWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultLengthWidth = newAccessor.getSomeIpStructLengthWidthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultLengthWidth === null)
            defaultLengthWidth = SOMEIP_DEFAULT_STRUCT_LENGTH_WIDTH

        var Integer lengthWidth = _accessor.getSomeIpStructLengthWidthHelper(_object)
        if(lengthWidth !== null && lengthWidth != defaultLengthWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            lengthWidth = newAccessor.getSomeIpStructLengthWidthHelper(_object)
            return lengthWidth !== null && lengthWidth != defaultLengthWidth
        }
        return false
    }

    def boolean hasSomeIpStringEncoding(PropertyAccessor _accessor, EObject _object) {
        var PropertyAccessor.SomeIpStringEncoding encoding = _accessor.getSomeIpStringEncoding(_object)
        if(encoding !== null && encoding != SOMEIP_DEFAULT_STRING_ENCODING) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            encoding = newAccessor.getSomeIpStringEncoding(_object)
            return encoding !== null && encoding != SOMEIP_DEFAULT_STRING_ENCODING
        }
        return false
    }

    def boolean hasSomeIpMapMinLength(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultMinLength = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultMinLength = _accessor.getSomeIpMapMinLengthHelper(_object.type.derived)
                    if (defaultMinLength === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultMinLength = newAccessor.getSomeIpMapMinLengthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultMinLength === null)
            defaultMinLength = SOMEIP_DEFAULT_MIN_LENGTH

        var Integer minLength = _accessor.getSomeIpMapMinLengthHelper(_object)
        if(minLength !== null && minLength != defaultMinLength) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            minLength = newAccessor.getSomeIpMapMinLengthHelper(_object)
            return minLength !== null && minLength != defaultMinLength
        }
        return false
    }

    def boolean hasSomeIpMapMaxLength(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultMaxLength = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultMaxLength = _accessor.getSomeIpMapMaxLengthHelper(_object.type.derived)
                    if (defaultMaxLength === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultMaxLength = newAccessor.getSomeIpMapMaxLengthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultMaxLength === null)
            defaultMaxLength = SOMEIP_DEFAULT_MAX_LENGTH

        var Integer maxLength = _accessor.getSomeIpMapMaxLengthHelper(_object)
        if(maxLength !== null && maxLength != defaultMaxLength) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            maxLength = newAccessor.getSomeIpMapMaxLengthHelper(_object)
            return maxLength !== null && maxLength != defaultMaxLength
        }
        return false
    }

    def boolean hasSomeIpMapLengthWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultLengthWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultLengthWidth = _accessor.getSomeIpMapLengthWidthHelper(_object.type.derived)
                    if (defaultLengthWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultLengthWidth = newAccessor.getSomeIpMapLengthWidthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultLengthWidth === null)
            defaultLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH

        var Integer lengthWidth = _accessor.getSomeIpMapLengthWidthHelper(_object)
        if(lengthWidth !== null && lengthWidth != defaultLengthWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            lengthWidth = newAccessor.getSomeIpMapLengthWidthHelper(_object)
            return lengthWidth !== null && lengthWidth != defaultLengthWidth
        }
        return false
    }

    def boolean hasSomeIpUnionLengthWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultLengthWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultLengthWidth = _accessor.getSomeIpUnionLengthWidthHelper(_object.type.derived)
                    if (defaultLengthWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultLengthWidth = newAccessor.getSomeIpUnionLengthWidthHelper(_object.type.derived)
                    }
                }
            }
          }
        if (defaultLengthWidth === null)
            defaultLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH

        var Integer lengthWidth = _accessor.getSomeIpUnionLengthWidthHelper(_object)
        if(lengthWidth !== null && lengthWidth != defaultLengthWidth) {
            return true
        }
        val newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            lengthWidth = newAccessor.getSomeIpUnionLengthWidthHelper(_object)
            return lengthWidth !== null && lengthWidth != defaultLengthWidth
        }
        return false
    }

    def boolean hasSomeIpUnionTypeWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultTypeWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultTypeWidth = _accessor.getSomeIpUnionTypeWidthHelper(_object.type.derived)
                    if (defaultTypeWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultTypeWidth = newAccessor.getSomeIpUnionTypeWidthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultTypeWidth === null)
            defaultTypeWidth = SOMEIP_DEFAULT_UNION_TYPE_WIDTH

        var Integer typeWidth = _accessor.getSomeIpUnionTypeWidthHelper(_object)
        if(typeWidth !== null && typeWidth != defaultTypeWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            typeWidth = newAccessor.getSomeIpUnionTypeWidthHelper(_object)
            return typeWidth !== null && typeWidth != defaultTypeWidth
        }
        return false
    }

    def boolean hasSomeIpUnionDefaultOrder(PropertyAccessor _accessor, EObject _object) {
        var Boolean defaultDefaultOrder = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultDefaultOrder = _accessor.getSomeIpUnionDefaultOrderHelper(_object.type.derived)
                    if (defaultDefaultOrder === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultDefaultOrder = newAccessor.getSomeIpUnionDefaultOrderHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultDefaultOrder === null)
            defaultDefaultOrder = SOMEIP_DEFAULT_UNION_DEFAULT_ORDER

        var Boolean defaultOrder = _accessor.getSomeIpUnionDefaultOrderHelper(_object)
        if(defaultOrder !== null && defaultOrder != defaultDefaultOrder) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            defaultOrder = newAccessor.getSomeIpUnionDefaultOrderHelper(_object)
            return defaultOrder !== null && defaultOrder != defaultDefaultOrder
        }
        return false
    }

    def boolean hasSomeIpUnionMaxLength(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultMaxLength = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultMaxLength = _accessor.getSomeIpUnionMaxLengthHelper(_object.type.derived)
                    if (defaultMaxLength === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultMaxLength = newAccessor.getSomeIpUnionMaxLengthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultMaxLength === null)
            defaultMaxLength = SOMEIP_DEFAULT_MAX_LENGTH

        var Integer maxLength = _accessor.getSomeIpUnionMaxLengthHelper(_object)
        if(maxLength !== null && maxLength != defaultMaxLength) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            maxLength = newAccessor.getSomeIpUnionMaxLengthHelper(_object)
            return maxLength !== null && maxLength != defaultMaxLength
        }
        return false
    }

    def boolean hasSomeIpEnumWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer defaultEnumWidth = null
        // overwrites are not used for defaults
        if (!_accessor.isProperOverwrite()) {
            if (_object instanceof FTypedElement) {
                if (_object.type.derived !== null) {
                    defaultEnumWidth = _accessor.getSomeIpEnumWidthHelper(_object.type.derived)
                    if (defaultEnumWidth === null) {
                        val newAccessor = getSpecificAccessor(_object)
                        if(newAccessor !== null)
                            defaultEnumWidth = newAccessor.getSomeIpEnumWidthHelper(_object.type.derived)
                    }
                }
            }
        }
        if (defaultEnumWidth === null)
            defaultEnumWidth = SOMEIP_DEFAULT_ENUM_LENGTH_WIDTH

        var Integer lengthWidth = _accessor.getSomeIpEnumWidthHelper(_object)
        if(lengthWidth !== null && lengthWidth != defaultEnumWidth) {
            return true
        }
        var newAccessor = getSpecificAccessor(_object)
        if(newAccessor !== null) {
            lengthWidth = newAccessor.getSomeIpEnumWidthHelper(_object)
            return lengthWidth !== null && lengthWidth != defaultEnumWidth
        }
        return false
    }

    def boolean hasSomeIpEnumBitWidth(PropertyAccessor _accessor, EObject _object) {
        var Integer width = _accessor.getSomeIpEnumBitWidthHelper(_object);
        if (width !== null && !isDefaultWidth(width.intValue()))
            return true

        var newAccessor = getSpecificAccessor(_object)
        if (newAccessor !== null) {
            width = newAccessor.getSomeIpEnumBitWidthHelper(_object)
            if (width !== null && !isDefaultWidth(width.intValue()))
                return true
        }

        return false
    }

    def boolean hasSomeIpEnumInvalidValue(PropertyAccessor _accessor, EObject _object) {
        var Integer invalidValue = _accessor.getSomeIpEnumInvalidValueHelper(_object)
        if (invalidValue !== null)
            return true

        var newAccessor = getSpecificAccessor(_object)
        if (newAccessor !== null) {
            invalidValue = newAccessor.getSomeIpEnumInvalidValueHelper(_object)
            if (invalidValue !== null)
                return true
        }

        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypedElement _element) {
        if (_accessor === null)
            return false
        if (_accessor.hasSomeIpArrayMinLength(_element) ||
            _accessor.hasSomeIpArrayMaxLength(_element) ||
            _accessor.hasSomeIpArrayLengthWidth(_element) ||
            _accessor.hasSomeIpMapMinLength(_element) ||
            _accessor.hasSomeIpMapMaxLength(_element) ||
            _accessor.hasSomeIpMapLengthWidth(_element) ||
            _accessor.hasSomeIpByteBufferMinLength(_element) ||
            _accessor.hasSomeIpByteBufferMaxLength(_element) ||
            _accessor.hasSomeIpByteBufferLengthWidth(_element) ||
            _accessor.hasSomeIpStringLength(_element) ||
            _accessor.hasSomeIpStringLengthWidth(_element) ||
            _accessor.hasSomeIpStringEncoding(_element) ||
            _accessor.hasSomeIpStructLengthWidth(_element) ||
            _accessor.hasSomeIpUnionLengthWidth(_element) ||
            _accessor.hasSomeIpUnionTypeWidth(_element) ||
            _accessor.hasSomeIpUnionDefaultOrder(_element) ||
            _accessor.hasSomeIpUnionMaxLength(_element) ||
            _accessor.hasSomeIpEnumWidth(_element) ||
            _accessor.hasSomeIpEnumBitWidth(_element) ||
            _accessor.hasSomeIpEnumInvalidValue(_element) ||
            _accessor.hasSomeIpIntegerBitWidth(_element) ||
            _accessor.hasSomeIpIntegerInvalidValue(_element)) {
                return true
        }
        return _accessor.hasDeployment(_element.type)
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FArrayType _array) {
        if (_accessor.hasSomeIpArrayMinLength(_array) ||
            _accessor.hasSomeIpArrayMaxLength(_array) ||
            _accessor.hasSomeIpArrayLengthWidth(_array)) {
            return true
        }
        var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(_array);
        if (overwriteAccessor.hasDeployment(_array.elementType)) {
            return true
        }

        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FMapType _map) {
        if (_accessor.hasSomeIpMapMinLength(_map) ||
            _accessor.hasSomeIpMapMaxLength(_map) ||
            _accessor.hasSomeIpMapLengthWidth(_map)) {
            return true
        }

        if (_accessor.hasDeployment(_map.keyType) ||
            _accessor.hasDeployment(_map.valueType)) {
            return true
        }

        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FEnumerationType _enum) {
        if (_accessor.hasSomeIpEnumWidth(_enum) ||
            _accessor.hasSomeIpEnumBitWidth(_enum) ||
            _accessor.hasSomeIpEnumInvalidValue(_enum))
            return true

        if (_enum.base !== null) {
            val itsBaseAccessor = getSomeIpAccessor(_enum.base.eContainer as FTypeCollection)
            if (itsBaseAccessor !== null)
                return itsBaseAccessor.hasDeployment(_enum.base)
        }

        return false 
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FStructType _struct) {
        if (_accessor.hasSomeIpStructLengthWidth(_struct))
            return true
        for (element : _struct.elements) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(element);
            if (overwriteAccessor.hasDeployment(element)) {
                return true
            }
        }

        if (_struct.base !== null) {
            return hasDeployment(_accessor, _struct.base);
        }

        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FUnionType _union) {
        if (_accessor.hasSomeIpUnionDefaultOrder(_union) ||
            _accessor.hasSomeIpUnionLengthWidth(_union) ||
            _accessor.hasSomeIpUnionTypeWidth(_union) ||
            _accessor.hasSomeIpUnionMaxLength(_union)) {
            return true
        }

        for (element : _union.elements) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(element);
            if (overwriteAccessor.hasDeployment(element)) {
                return true
            }
        }

        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypeDef _typeDef) {
        return _accessor.hasDeployment(_typeDef.actualType)
    }
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FIntegerInterval _type) {
        return false
    }
    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FBasicTypeId _type) {
        return false
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FType _type) {
        return false;
    }

    def dispatch boolean hasDeployment(PropertyAccessor _accessor, FTypeRef _type) {
        if (_type.derived !== null)
            return _accessor.hasDeployment(_type.derived)
        if (_type.interval !== null)
            return _accessor.hasDeployment(_type.interval)
        if (_type.predefined !== null)
            return _accessor.hasDeployment(_type.predefined)

        return false
    }

    def boolean isFull(FBasicTypeId _type, Integer _width) {
        if (_type === null)
            return false

        if (_type == FBasicTypeId.INT8 || _type == FBasicTypeId.INT8)
            return _width == 8

        if (_type == FBasicTypeId.INT16 || _type == FBasicTypeId.INT16)
            return _width == 16

        if (_type == FBasicTypeId.INT32 || _type == FBasicTypeId.INT32)
            return _width == 32

        if (_type == FBasicTypeId.INT64 || _type == FBasicTypeId.INT64)
            return _width == 64

        return false
    }

    def boolean hasSpecificDeployment(PropertyAccessor _accessor, FTypedElement _element) {
        val PropertyAccessor itsBaseAccessor =
        if (_accessor.isProperOverwrite() )
            _accessor.parent
        else
            null

        val itsSpecificArrayMinLength = _accessor.getSomeIpArrayMinLengthHelper(_element)
        var itsArrayMinLength = SOMEIP_DEFAULT_MIN_LENGTH
        if (itsBaseAccessor !== null) {
            itsArrayMinLength = _accessor.getSomeIpArrayMinLengthHelper(_element)
        }
        if (itsSpecificArrayMinLength !== null
            && itsSpecificArrayMinLength != itsArrayMinLength
            && itsSpecificArrayMinLength != SOMEIP_DEFAULT_MIN_LENGTH) {
            return true
        }

        val itsSpecificArrayMaxLength = _accessor.getSomeIpArrayMaxLengthHelper(_element)
        var itsArrayMaxLength = SOMEIP_DEFAULT_MAX_LENGTH
        if (itsBaseAccessor !== null) {
            itsArrayMaxLength = _accessor.getSomeIpArrayMaxLengthHelper(_element)
        }
        if (itsSpecificArrayMaxLength !== null
            && itsSpecificArrayMaxLength != itsArrayMaxLength
            && itsSpecificArrayMaxLength != SOMEIP_DEFAULT_MAX_LENGTH) {
            return true
        }

        val itsSpecificArrayLengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_element)
        var itsArrayLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH
        if (itsBaseAccessor !== null) {
            itsArrayLengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_element)
        }
        if (itsSpecificArrayLengthWidth !== null
            && itsSpecificArrayLengthWidth != itsArrayLengthWidth
            && itsSpecificArrayLengthWidth != SOMEIP_DEFAULT_LENGTH_WIDTH) {
            return true
        }
        val itsSpecificMapMinLength = _accessor.getSomeIpMapMinLengthHelper(_element)
        var itsMapMinLength = SOMEIP_DEFAULT_MIN_LENGTH
        if (itsBaseAccessor !== null) {
            itsMapMinLength = _accessor.getSomeIpMapMinLengthHelper(_element)
        }
        if (itsSpecificMapMinLength !== null
            && itsSpecificMapMinLength != itsMapMinLength
            && itsSpecificMapMinLength != SOMEIP_DEFAULT_MIN_LENGTH) {
            return true
        }

        val itsSpecificMapMaxLength = _accessor.getSomeIpMapMaxLengthHelper(_element)
        var itsMapMaxLength = SOMEIP_DEFAULT_MAX_LENGTH
        if (itsBaseAccessor !== null) {
            itsMapMaxLength = _accessor.getSomeIpMapMaxLengthHelper(_element)
        }
        if (itsSpecificMapMaxLength !== null
            && itsSpecificMapMaxLength != itsMapMaxLength
            && itsSpecificMapMaxLength != SOMEIP_DEFAULT_MAX_LENGTH) {
            return true
        }

        val itsSpecificMapLengthWidth = _accessor.getSomeIpMapLengthWidthHelper(_element)
        var itsMapLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH
        if (itsBaseAccessor !== null) {
            itsMapLengthWidth = itsBaseAccessor.getSomeIpMapLengthWidthHelper(_element)
        }
        if (itsSpecificMapLengthWidth !== null
            && itsSpecificMapLengthWidth != itsMapLengthWidth
            && itsSpecificMapLengthWidth != SOMEIP_DEFAULT_LENGTH_WIDTH) {
            return true
        }

        val itsSpecificByteBufferMinLength = _accessor.getSomeIpByteBufferMinLength(_element)
        var itsByteBufferMinLength = SOMEIP_DEFAULT_MIN_LENGTH
        if (itsBaseAccessor !== null) {
            itsByteBufferMinLength = _accessor.getSomeIpByteBufferMinLength(_element)
        }
        if (itsSpecificByteBufferMinLength !== null
            && itsSpecificByteBufferMinLength != itsByteBufferMinLength
            && itsSpecificByteBufferMinLength != SOMEIP_DEFAULT_MIN_LENGTH) {
            return true
        }

        val itsSpecificByteBufferMaxLength = _accessor.getSomeIpByteBufferMaxLength(_element)
        var itsByteBufferMaxLength = SOMEIP_DEFAULT_MAX_LENGTH
        if (itsBaseAccessor !== null) {
            itsByteBufferMaxLength = _accessor.getSomeIpByteBufferMaxLength(_element)
        }
        if (itsSpecificByteBufferMaxLength !== null
            && itsSpecificByteBufferMaxLength != itsByteBufferMaxLength 
            && itsSpecificByteBufferMaxLength != SOMEIP_DEFAULT_MAX_LENGTH) {
            return true
        }

        val itsSpecificByteBufferLengthWidth = _accessor.getSomeIpByteBufferLengthWidth(_element)
        var itsByteBufferLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH
        if (itsBaseAccessor !== null) {
            itsByteBufferLengthWidth = itsBaseAccessor.getSomeIpByteBufferLengthWidth(_element)
        }
        if (itsSpecificByteBufferLengthWidth !== null
            && itsSpecificByteBufferLengthWidth != itsByteBufferLengthWidth
            && itsSpecificByteBufferLengthWidth != SOMEIP_DEFAULT_LENGTH_WIDTH) {
            return true
        }

        val itsSpecificStringLength = _accessor.getSomeIpStringLength(_element)
        var Integer itsStringLength = SOMEIP_DEFAULT_STRING_LENGTH
        if (itsBaseAccessor !== null) {
            itsStringLength = itsBaseAccessor.getSomeIpStringLength(_element)
        }
        if (itsSpecificStringLength !== null
            && itsSpecificStringLength != itsStringLength
            && itsSpecificStringLength != SOMEIP_DEFAULT_STRING_LENGTH) {
            return true
        }

        val itsSpecificStringLengthWidth = _accessor.getSomeIpStringLengthWidth(_element)
        var itsStringLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH
        if (itsBaseAccessor !== null) {
            itsStringLengthWidth = itsBaseAccessor.getSomeIpStringLengthWidth(_element)
        }
        if (itsSpecificStringLengthWidth !== null
            && itsSpecificStringLengthWidth != itsStringLengthWidth 
            && itsSpecificStringLengthWidth != SOMEIP_DEFAULT_LENGTH_WIDTH) {
            return true
        }

        val itsSpecificStringEncoding = _accessor.getSomeIpStringEncoding(_element)
        var itsStringEncoding = SOMEIP_DEFAULT_STRING_ENCODING
        if (itsBaseAccessor !== null) {
            itsStringEncoding = itsBaseAccessor.getSomeIpStringEncoding(_element)
        }
        if (itsSpecificStringEncoding !== null
            && itsSpecificStringEncoding != itsStringEncoding
            && itsSpecificStringEncoding != SOMEIP_DEFAULT_STRING_ENCODING) {
            return true
        }

        val itsSpecificStructLengthWidth = _accessor.getSomeIpStructLengthWidthHelper(_element)
        var itsStructLengthWidth = SOMEIP_DEFAULT_STRUCT_LENGTH_WIDTH
        if (itsBaseAccessor !== null) {
            itsStructLengthWidth = itsBaseAccessor.getSomeIpStructLengthWidthHelper(_element)
        }
        if (itsSpecificStructLengthWidth !== null
            && itsSpecificStructLengthWidth != itsStructLengthWidth
            && itsSpecificStructLengthWidth != SOMEIP_DEFAULT_STRUCT_LENGTH_WIDTH) {
            return true
        }

        val itsSpecificUnionLengthWidth = _accessor.getSomeIpUnionLengthWidthHelper(_element)
        var itsUnionLengthWidth = SOMEIP_DEFAULT_LENGTH_WIDTH
        if (itsBaseAccessor !== null) {
            itsUnionLengthWidth = itsBaseAccessor.getSomeIpUnionLengthWidthHelper(_element)
        }
        if (itsSpecificUnionLengthWidth !== null
            && itsSpecificUnionLengthWidth != itsUnionLengthWidth
            && itsSpecificUnionLengthWidth != SOMEIP_DEFAULT_LENGTH_WIDTH) {
            return true
        }

        val itsSpecificUnionTypeWidth = _accessor.getSomeIpUnionTypeWidthHelper(_element)
        var itsUnionTypeWidth = SOMEIP_DEFAULT_UNION_TYPE_WIDTH
        if (itsBaseAccessor !== null) {
            itsUnionTypeWidth = itsBaseAccessor.getSomeIpUnionTypeWidthHelper(_element)
        }
        if (itsSpecificUnionTypeWidth !== null
            && itsSpecificUnionTypeWidth != itsUnionTypeWidth
            && itsSpecificUnionTypeWidth != SOMEIP_DEFAULT_UNION_TYPE_WIDTH) {
            return true
        }

        val itsSpecificUnionDefaultOrder = _accessor.getSomeIpUnionDefaultOrderHelper(_element)
        var Boolean itsUnionDefaultOrder = SOMEIP_DEFAULT_UNION_DEFAULT_ORDER
        if (itsBaseAccessor !== null) {
            itsUnionDefaultOrder = itsBaseAccessor.getSomeIpUnionDefaultOrderHelper(_element)
        }
        if (itsSpecificUnionDefaultOrder !== null
            && itsSpecificUnionDefaultOrder != itsUnionDefaultOrder
            && itsSpecificUnionDefaultOrder != SOMEIP_DEFAULT_UNION_DEFAULT_ORDER) {
            return true
        }

        val itsSpecificUnionMaxLength = _accessor.getSomeIpUnionMaxLengthHelper(_element)
        var itsUnionMaxLength = SOMEIP_DEFAULT_MAX_LENGTH
        if (itsBaseAccessor !== null) {
            itsUnionMaxLength = itsBaseAccessor.getSomeIpUnionMaxLengthHelper(_element)
        }
        if (itsSpecificUnionMaxLength !== null
            && itsSpecificUnionMaxLength != itsUnionMaxLength
            && itsSpecificUnionMaxLength != SOMEIP_DEFAULT_MAX_LENGTH) {
            return true
        }

        val itsSpecificEnumWidth = _accessor.getSomeIpEnumWidthHelper(_element)
        var itsEnumWidth = SOMEIP_DEFAULT_ENUM_WIDTH
        if (itsBaseAccessor !== null) {
            itsEnumWidth = itsBaseAccessor.getSomeIpEnumWidthHelper(_element)
        }
        if (itsSpecificEnumWidth !== null
            && itsSpecificEnumWidth != itsEnumWidth
            && itsSpecificEnumWidth != SOMEIP_DEFAULT_ENUM_WIDTH) {
            return true
        }

        val itsSpecificEnumBitWidth = _accessor.getSomeIpEnumBitWidthHelper(_element)
        var Integer itsEnumBitWidth = null
        if (itsEnumWidth !== null) {
            itsEnumBitWidth = (itsEnumWidth << 3)
        }
        if (itsBaseAccessor !== null) {
            itsEnumBitWidth = itsBaseAccessor.getSomeIpEnumBitWidthHelper(_element)
        }
        if (itsSpecificEnumBitWidth !== null
            && itsSpecificEnumBitWidth != itsEnumBitWidth
            && itsSpecificEnumBitWidth != (itsEnumWidth << 3)) {
            return true;
        }

        val itsSpecificEnumInvalidValue = _accessor.getSomeIpEnumInvalidValueHelper(_element)
        var Integer itsEnumInvalidValue = null
        if (itsBaseAccessor !== null) {
            itsEnumInvalidValue = itsBaseAccessor.getSomeIpEnumInvalidValueHelper(_element)
        }
        if (itsSpecificEnumInvalidValue !== null
            && itsSpecificEnumInvalidValue != itsEnumInvalidValue) {
            return true;
        }

        val itsSpecificIntegerBitWidth = _accessor.getSomeIpIntegerBitWidthHelper(_element)
        var Integer itsIntegerBitWidth = null
        if (itsBaseAccessor !== null) {
            itsIntegerBitWidth = itsBaseAccessor.getSomeIpIntegerBitWidthHelper(_element)
        }
        if (itsSpecificIntegerBitWidth !== null
            && itsSpecificIntegerBitWidth != itsIntegerBitWidth) {
            return !isFull(_element.type.predefined, itsSpecificIntegerBitWidth)
        }

        val itsSpecificIntegerInvalidValue = _accessor.getSomeIpIntegerInvalidValueHelper(_element)
        var Integer itsIntegerInvalidValue = null
        if (itsBaseAccessor !== null) {
            itsIntegerInvalidValue = itsBaseAccessor.getSomeIpIntegerInvalidValueHelper(_element)
        }
        if (itsSpecificIntegerInvalidValue !== null
            && itsSpecificIntegerInvalidValue != itsIntegerInvalidValue) {
            return true;
        }

        // also check for overwrites
        if (_accessor.isProperOverwrite()) {
            return true
        }

        return false
    }
    
    def boolean hasNonArrayDeployment(PropertyAccessor _accessor,
                                      FTypedElement _attribute) {
        if (_attribute.type.derived !== null
            && _attribute.type.derived instanceof FMapType) {
            if (hasSomeIpMapMinLength(_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpMapMaxLength (_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpMapLengthWidth (_accessor, _attribute)) {
                return true
            }
        }

        if (_attribute.type.predefined !== null
            && _attribute.type.predefined == FBasicTypeId.BYTE_BUFFER) {
            if (hasSomeIpByteBufferMinLength(_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpByteBufferMaxLength(_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpByteBufferLengthWidth(_accessor, _attribute)) {
                return true
            }
        }

        if (_attribute.type.predefined !== null
            && _attribute.type.predefined == FBasicTypeId.STRING) {
            if (hasSomeIpStringLength (_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpStringLengthWidth (_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpStringEncoding (_accessor, _attribute)) {
                return true
            }
        }

        if (_attribute.type.derived !== null
            && _attribute.type.derived instanceof FStructType) {
            if (hasSomeIpStructLengthWidth (_accessor, _attribute)) {
                return true
            }
            val struct = _attribute.type.derived as FStructType
            if (_accessor.isProperOverwrite()) {
                for (element : struct.elements) {
                    if (_accessor.hasSpecificDeployment(element)) {
                        return true
                    }
                }
            }
        }

        if (_attribute.type.derived !== null
            && _attribute.type.derived instanceof FUnionType) {
            if (hasSomeIpUnionLengthWidth (_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpUnionTypeWidth (_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpUnionDefaultOrder (_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpUnionMaxLength (_accessor, _attribute)) {
                return true
            }
            val union = _attribute.type.derived as FUnionType
            if (_accessor.isProperOverwrite()) {
                for (element : union.elements) {
                    if (_accessor.hasSpecificDeployment(element)) {
                        return true
                    }
                }
            }
        }

        if (_attribute.type.derived !== null
            && _attribute.type.derived instanceof FEnumerationType) {
            if (hasSomeIpEnumWidth(_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpEnumBitWidth(_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpEnumInvalidValue (_accessor, _attribute)) {
                return true
            }
        }

        if (_attribute.type.predefined !== null
            && (_attribute.type.predefined == FBasicTypeId.INT8
                || _attribute.type.predefined == FBasicTypeId.INT16
                || _attribute.type.predefined == FBasicTypeId.INT32
                || _attribute.type.predefined == FBasicTypeId.INT64
                || _attribute.type.predefined == FBasicTypeId.UINT8
                || _attribute.type.predefined == FBasicTypeId.UINT16
                || _attribute.type.predefined == FBasicTypeId.UINT32
                || _attribute.type.predefined == FBasicTypeId.UINT64)) {
            if (hasSomeIpIntegerBitWidth (_accessor, _attribute)) {
                return true
            }
            if (hasSomeIpIntegerInvalidValue (_accessor, _attribute)) {
                return true
            }
        }

        return false
    }
}
