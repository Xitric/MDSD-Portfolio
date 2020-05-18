package org.iot.devicefactory.typing

import com.google.inject.Inject
import org.iot.devicefactory.deviceFactory.Data
import org.iot.devicefactory.deviceFactory.Out
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.SensorData
import org.iot.devicefactory.deviceFactory.TransformationData

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class DeviceFactoryTypeChecker {
	
	@Inject extension DeviceLibraryTypeChecker
	
	def typeOf(Data data, ExpressionTypeChecker typeChecker) {
		val baseData = data.baseData
		switch baseData {
			SensorData: baseData.outputs.head.typeOf(typeChecker)
			TransformationData: baseData.outputs.head.typeOf(typeChecker)
		}
	}
	
	def typeOf(Out output, extension ExpressionTypeChecker typeChecker) {
		val pipelineType = output.pipeline.outputTypeOfPipeline
		
		if (pipelineType === ExpressionType.VOID) {
			return output.getContainerOfType(Sensor).definition.typeOf(typeChecker)
		}
		
		return pipelineType
	}
}
