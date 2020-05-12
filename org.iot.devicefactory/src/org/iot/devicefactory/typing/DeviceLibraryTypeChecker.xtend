package org.iot.devicefactory.typing

import com.google.inject.Inject
import java.util.Arrays
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.common.VariableDeclaration
import org.iot.devicefactory.common.Variables
import org.iot.devicefactory.deviceLibrary.BaseSensor
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.deviceLibrary.Sensor

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.iot.devicefactory.util.DeviceLibraryUtils.*

class DeviceLibraryTypeChecker {
	
	@Inject extension ExpressionTypeChecker
	
	def ExpressionType typeOf(Sensor sensor) {
		if (sensor.preprocess !== null) {
			val preprocessType = sensor.preprocess.pipeline.typeOfPipeline
			if (preprocessType !== VOID) {
				return preprocessType
			}
		}
		
		switch sensor {
			BaseSensor: sensor.input.variables.typeOf
			OverrideSensor: sensor.parentSensor.typeOf
		}
	}
	
	private def typeOf(VariableDeclaration variableDeclaration) {
		switch variableDeclaration {
			Variable: INTEGER
			Variables: {
				val ExpressionType[] type = ArrayLiterals.newArrayOfSize(variableDeclaration.vars.size)
				Arrays.fill(type, INTEGER)
				TUPLE(type)
			}
		}
	}
}
