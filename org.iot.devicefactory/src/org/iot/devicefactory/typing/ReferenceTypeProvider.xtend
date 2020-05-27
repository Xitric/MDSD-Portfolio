package org.iot.devicefactory.typing

import com.google.inject.Inject
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Reference
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.common.Variables
import org.iot.devicefactory.deviceFactory.Transformation
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.eclipse.xtext.EcoreUtil2.*

class ReferenceTypeProvider {
	
	@Inject extension DeviceFactoryTypeChecker

	def typeOf(Reference ref, ExpressionTypeChecker typeChecker) {
		val variable = ref.variable

		val map = variable.getContainerOfType(Map)
		if (map !== null) {
			return variable.getMapType(map, typeChecker)
		}

		val baseSensor = variable.getContainerOfType(BaseSensorDefinition)
		if (baseSensor !== null) {
			return getBaseSensorType()
		}
		
		val transformation = variable.getContainerOfType(Transformation)
		if (transformation !== null) {
			return variable.getTransformationType(transformation, typeChecker)
		}

		getFallbackType()
	}

	private def getMapType(Variable variable, Map map, extension ExpressionTypeChecker typeChecker) {
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

	private def getBaseSensorType() {
		INTEGER
	}
	
	private def getTransformationType(Variable variable, Transformation transformation, extension ExpressionTypeChecker typeChecker) {
		val dataType = transformation.provider.typeOf(typeChecker)
		val variableContainer = variable.eContainer
		
		switch variableContainer {
			Variables: {
				val index = variableContainer.vars.indexOf(variable)
				switch dataType {
					TupleExpressionType case dataType.elements.size > index: dataType.elements.get(index)
					default: VOID
				}
			}
			default: {
				switch dataType {
					TupleExpressionType: VOID
					ExpressionType: dataType
					default: VOID
				}
			}
		}
	}

	private def getFallbackType() {
		VOID
	}
}
