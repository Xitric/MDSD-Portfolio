package org.iot.devicefactory.typing

import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Reference
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.common.Variables
import org.iot.devicefactory.deviceLibrary.BaseSensor

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.eclipse.xtext.EcoreUtil2.*

class ReferenceTypeProvider {

	static def typeOf(Reference ref, ExpressionTypeChecker typeChecker) {
		val variable = ref.variable

		val map = variable.getContainerOfType(Map)
		if (map !== null) {
			return variable.getMapType(map, typeChecker)
		}

		val baseSensor = variable.getContainerOfType(BaseSensor)
		if (baseSensor !== null) {
			return getBaseSensorType()
		}

		getFallbackType()
	}

	private static def getMapType(Variable variable, Map map, extension ExpressionTypeChecker typeChecker) {
		val mapType = map.expression.typeOf

		switch mapType {
			TupleExpressionType: {
				val variables = variable.getContainerOfType(Variables)
				if (variables !== null) {
					val varIndex = variables.vars.indexOf(variable)
					return mapType.elements.get(varIndex)
				} else {
					return getFallbackType()
				}
			}
			default: {
				return mapType
			}
		}
	}

	private static def getBaseSensorType() {
		INTEGER
	}

	private static def getFallbackType() {
		VOID
	}
}
