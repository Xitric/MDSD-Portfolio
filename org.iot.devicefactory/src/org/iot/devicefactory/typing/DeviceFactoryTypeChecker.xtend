package org.iot.devicefactory.typing

import com.google.inject.Inject
import org.iot.devicefactory.deviceFactory.Data
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.SensorData
import org.iot.devicefactory.deviceFactory.SensorDataOut
import org.iot.devicefactory.deviceFactory.TransformationData
import org.iot.devicefactory.deviceFactory.TransformationOut

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class DeviceFactoryTypeChecker {
	
	@Inject extension ExpressionTypeChecker
	@Inject extension DeviceLibraryTypeChecker
	
	def typeOf(Data data) {
		val baseData = data.baseData
		switch baseData {
			SensorData: baseData.outputs.head.typeOf
			TransformationData: baseData.outputs.head.typeOf
		}
	}
	
	// TODO: common super type in meta model to simplify code
	def typeOf(SensorDataOut output) {
		val pipelineType = output.pipeline.typeOfPipeline
		
		if (pipelineType === ExpressionType.VOID) {
			return output.getContainerOfType(Sensor).definition.typeOf
		}
		
		return pipelineType
	}
	
	def typeOf(TransformationOut output) {
		val pipelineType = output.pipeline.typeOfPipeline
		
		if (pipelineType === ExpressionType.VOID) {
			return output.getContainerOfType(Sensor).definition.typeOf
		}
		
		return pipelineType
	}
}
