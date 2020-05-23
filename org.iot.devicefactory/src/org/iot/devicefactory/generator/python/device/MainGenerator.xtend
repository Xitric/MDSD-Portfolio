package org.iot.devicefactory.generator.python.device

import org.iot.devicefactory.deviceFactory.Device

import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*

class MainGenerator {
	
	// TODO: Ensure correct comments and works at runtime :P
	def String compile(Device device) {
		'''
			from composition_root import CompositionRoot
			
			class CustomCompositionRoot(CompositionRoot):
				# This file will not be overwritten by the DeviceFactory code generator.
				# 
				# To adapt the generated code, override the methods from CompositionRoot
				# inside this class, for instance:
				# 
				# def provide_«device.name.asModule»(self):
				#     device = super().provide_«device.name.asModule»()
				#     device.add_sensor(...)
				«IF device.input !== null»
					#     device.set_input_channel(...)
				«ENDIF»
				#     device.add_output_channel(...)
				# 
				# You should also override the sensor driver providers for all sensors
				# connected over i2c, such as:
				# def provide_driver_motion(self):
				# 	  return MPU6050()
				pass
			
			CustomCompositionRoot().provide_«device.name.asModule»().run()
		'''
	}
}
