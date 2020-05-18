package org.iot.devicefactory.typing

import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.common.VariableDeclaration
import org.iot.devicefactory.common.Variables
import org.iot.devicefactory.deviceLibrary.BaseSensor
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.deviceLibrary.Sensor

import static org.iot.devicefactory.typing.ExpressionType.*

class DeviceLibraryTypeChecker {
	
	def ExpressionType typeOf(Sensor sensor, extension ExpressionTypeChecker typeChecker) {
		if (sensor.preprocess !== null) {
			val preprocessType = sensor.preprocess.pipeline.outputTypeOfPipeline
			if (preprocessType !== VOID) {
				return preprocessType
			}
		}
		
		switch sensor {
			BaseSensor: sensor.input.variables.typeOf
			OverrideSensor: sensor.parent.typeOf(typeChecker)
		}
	}
	
	def typeOf(VariableDeclaration variableDeclaration) {
		switch variableDeclaration {
			Variable: INTEGER
			Variables: TUPLE(INTEGER, variableDeclaration.vars.size)
		}
	}
}
