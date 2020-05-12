package org.iot.devicefactory.typing

import com.google.inject.Inject
import org.iot.devicefactory.deviceFactory.Data
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.SensorDataOut

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class DeviceFactoryTypeChecker {
	
	@Inject extension ExpressionTypeChecker
	@Inject extension DeviceLibraryTypeChecker
	
	def typeOf(Data data) {
		data.baseData.outputs.head.typeOf
	}
	
	def typeOf(SensorDataOut output) {
		val pipelineType = output.pipeline.typeOfPipeline
		
		if (pipelineType === ExpressionType.VOID) {
			return output.getContainerOfType(Sensor).definition.typeOf
		}
		
		return pipelineType
	}
}
