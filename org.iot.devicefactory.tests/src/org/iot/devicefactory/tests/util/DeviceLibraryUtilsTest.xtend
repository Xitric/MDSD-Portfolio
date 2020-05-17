package org.iot.devicefactory.tests.util

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.tests.DeviceLibraryInjectorProvider
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(DeviceLibraryInjectorProvider)
class DeviceLibraryUtilsTest {
	
	@Inject extension ParseHelper<Library>
	
	@Test def void testParentSensor() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			override sensor a
				preprocess filter[true]
		
		define board BoardC includes BoardB
			override sensor a
				preprocess filter[true]
		'''.parse.boards => [
			(get(1).sensors.get(0) as OverrideSensor).parent.assertSame(
				get(0).sensors.get(0)
			)
			(get(2).sensors.get(0) as OverrideSensor).parent.assertSame(
				get(1).sensors.get(0)
			)
		]
	}
}
