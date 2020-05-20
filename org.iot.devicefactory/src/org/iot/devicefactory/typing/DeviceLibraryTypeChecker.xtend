package org.iot.devicefactory.typing

import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.common.VariableDeclaration
import org.iot.devicefactory.common.Variables
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition
import org.iot.devicefactory.deviceLibrary.OverrideSensorDefinition
import org.iot.devicefactory.deviceLibrary.SensorDefinition

import static org.iot.devicefactory.typing.ExpressionType.*

class DeviceLibraryTypeChecker {
	
	def ExpressionType typeOf(SensorDefinition sensor, extension ExpressionTypeChecker typeChecker) {
		if (sensor.preprocess?.pipeline !== null) {
			return sensor.preprocess.pipeline.outputTypeOfPipeline
		}
		
		switch sensor {
			BaseSensorDefinition: sensor.input.variables.typeOf
			OverrideSensorDefinition: sensor.parent.typeOf(typeChecker)
		}
	}
	
	def typeOf(VariableDeclaration variableDeclaration) {
		switch variableDeclaration {
			Variable: INTEGER
			Variables: TUPLE(INTEGER, variableDeclaration.vars.size)
		}
	}
}
