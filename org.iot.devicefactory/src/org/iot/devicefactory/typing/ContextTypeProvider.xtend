package org.iot.devicefactory.typing

import com.google.inject.Inject
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.deviceFactory.Transformation
import org.iot.devicefactory.deviceLibrary.BaseSensor
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.deviceLibrary.Sensor

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
		val libSensor = pipeline.getContainerOfType(Sensor)
		if (libSensor !== null) {
			return libSensor.getLibrarySensorContextType(typeChecker)
		}
		
		val facSensor = pipeline.getContainerOfType(org.iot.devicefactory.deviceFactory.Sensor)
		if (facSensor !== null) {
			return facSensor.getFactorySensorContextType(typeChecker)
		}
		
		val transformation = pipeline.getContainerOfType(Transformation)
		if (transformation !== null) {
			return transformation.getTransformationContextType(typeChecker)
		}
		
		return ExpressionType.VOID
	}
	
	private def getLibrarySensorContextType(Sensor sensor, ExpressionTypeChecker typeChecker) {
		switch sensor {
			BaseSensor: sensor.input.variables.typeOf
			OverrideSensor: sensor.parent.typeOf(typeChecker)
			default: ExpressionType.VOID
		}
	}
	
	private def getFactorySensorContextType(org.iot.devicefactory.deviceFactory.Sensor sensor, ExpressionTypeChecker typeChecker) {
		sensor.definition?.typeOf(typeChecker) ?: ExpressionType.VOID
	}
	
	private def getTransformationContextType(Transformation transformation, ExpressionTypeChecker typeChecker) {
		transformation.provider.typeOf(typeChecker)
	}
}
