package org.iot.devicefactory.tests.validation

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.deviceFactory.DeviceFactoryPackage.Literals
import org.iot.devicefactory.tests.MultiLanguageInjectorProvider
import org.iot.devicefactory.tests.TestUtil
import org.iot.devicefactory.validation.DeviceFactoryIssueCodes
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class DeviceFactoryTransformationValidationTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ValidationTestHelper
	@Inject extension TestUtil
	
	@Test def void testTransformationVariablesPrimitive() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint map[b * b => a]
		fog
			transformation raw_pressure as a
				data fog_data
					out filter[true]
		'''.parse(resourceSet).assertNoError(DeviceFactoryIssueCodes.INCORRECT_VARIABLE_DECLARATION)
		
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint map[b * b => a]
		fog
			transformation raw_pressure as (a, b)
				data fog_data
					out filter[true]
		'''.parse(resourceSet).assertError(
			Literals.TRANSFORMATION,
			DeviceFactoryIssueCodes.INCORRECT_VARIABLE_DECLARATION,
			"Expected variable declaration to contain 1 variable, got 2"
		)
	}
	
	@Test def void testTransformationVariablesTuple() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint map[(b, b) => (x, y)]
		cloud
			transformation raw_pressure as a
				data cloud_data
					out filter[true]
		'''.parse(resourceSet).assertError(
			Literals.TRANSFORMATION,
			DeviceFactoryIssueCodes.INCORRECT_VARIABLE_DECLARATION,
			"Expected variable declaration to contain 2 variables, got 1"
		)
		
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint map[(b, b) => (x, y)]
		cloud
			transformation raw_pressure as (a, b)
				data cloud_data
					out filter[true]
		'''.parse(resourceSet).assertNoErrors(DeviceFactoryIssueCodes.INCORRECT_VARIABLE_DECLARATION)
	}
	
	@Test def void testTransformationVariablesChain() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint map[b => a]
		fog
			transformation raw_pressure as x
				data fog_data
					out map[(x, x) => (i, j)]
		cloud
			transformation fog_data as (a, b)
				data cloud_data
					out filter[true]
		'''.parse(resourceSet).assertNoErrors(DeviceFactoryIssueCodes.INCORRECT_VARIABLE_DECLARATION)
		
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint map[b => a]
		fog
			transformation raw_pressure as x
				data fog_data
					out map[(x, x) => (i, j)]
		cloud
			transformation fog_data as a
				data cloud_data
					out filter[true]
		'''.parse(resourceSet).assertError(
			Literals.TRANSFORMATION,
			DeviceFactoryIssueCodes.INCORRECT_VARIABLE_DECLARATION,
			"Expected variable declaration to contain 2 variables, got 1"
		)
	}
}
