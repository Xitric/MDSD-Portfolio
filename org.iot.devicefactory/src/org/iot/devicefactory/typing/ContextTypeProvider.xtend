package org.iot.devicefactory.typing

import com.google.inject.Inject
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.Transformation
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition
import org.iot.devicefactory.deviceLibrary.OverrideSensorDefinition
import org.iot.devicefactory.deviceLibrary.SensorDefinition

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

/**
 * A class responsible for getting the input types to pipelines when they are
 * used inside out declarations and preprocessers.
 */
class ContextTypeProvider {
	
	@Inject extension DeviceLibraryTypeChecker
	@Inject extension DeviceFactoryTypeChecker
	
	def getContextType(Pipeline pipeline, ExpressionTypeChecker typeChecker) {
		val libSensor = pipeline.getContainerOfType(SensorDefinition)
		if (libSensor !== null) {
			return libSensor.getLibrarySensorContextType(typeChecker)
		}
		
		val facSensor = pipeline.getContainerOfType(Sensor)
		if (facSensor !== null) {
			return facSensor.getFactorySensorContextType(typeChecker)
		}
		
		val transformation = pipeline.getContainerOfType(Transformation)
		if (transformation !== null) {
			return transformation.getTransformationContextType(typeChecker)
		}
		
		return ExpressionType.VOID
	}
	
	private def getLibrarySensorContextType(SensorDefinition sensor, ExpressionTypeChecker typeChecker) {
		switch sensor {
			BaseSensorDefinition: sensor.input.variables.typeOf
			OverrideSensorDefinition: sensor.parent.typeOf(typeChecker)
			default: ExpressionType.VOID
		}
	}
	
	private def getFactorySensorContextType(Sensor sensor, ExpressionTypeChecker typeChecker) {
		sensor.definition?.typeOf(typeChecker) ?: ExpressionType.VOID
	}
	
	private def getTransformationContextType(Transformation transformation, ExpressionTypeChecker typeChecker) {
		transformation.provider.typeOf(typeChecker)
	}
}
