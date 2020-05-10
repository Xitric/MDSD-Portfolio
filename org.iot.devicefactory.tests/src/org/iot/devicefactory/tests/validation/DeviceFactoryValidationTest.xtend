package org.iot.devicefactory.tests.validation

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.eclipse.xtext.util.StringInputStream
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.deviceFactory.DeviceFactoryPackage.Literals
import org.iot.devicefactory.tests.MultiLanguageInjectorProvider
import org.iot.devicefactory.validation.DeviceFactoryValidator
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import org.eclipse.xtext.diagnostics.Diagnostic

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class DeviceFactoryValidationTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ValidationTestHelper
	@Inject Provider<ResourceSet> resourceSetProvider
	
	@Test def void testDeploymentNoChannel() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.MISSING_CHANNEL,
			"There must be at least one channel"
		)
	}
	
	@Test def void testDeploymentNoDevice() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.MISSING_DEVICE,
			"There must be at least one device"
		)
	}
	
	@Test def void testDeploymentMultipleFogs() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		fog
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		fog
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.AMBIGUOUS_FOG,
			"There can be at most one fog"
		)
	}
	
	@Test def void testDeploymentNoCloud() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.MISSING_CLOUD,
			"There must be a cloud"
		)
	}
	
	@Test def void testDeploymentMultipleClouds() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		cloud
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		cloud
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.AMBIGUOUS_CLOUD,
			"There can be at most one cloud"
		)
	}
	
	@Test def void testIllegalBoardReference() {
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse.assertError(
			Literals.BASE_DEVICE,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Board 'esp32'"
		)
	}
	
	@Test def void testFullyQualifiedBoard() {
		val resourceSet = makeBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board iot.boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testImportedBoard() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.esp32
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testWildcardImport() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testPackageImport() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.*
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testPackageImportNoWildcard() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.BASE_DEVICE,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Board 'boards.esp32'"
		)
	}
	
	@Test def void testLegalDeployment() {
		val resourceSet = makeBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		device mega_controller includes controller
			override sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		fog
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		cloud
			transformation scaled_pressure as t
				data new_pressure
					out filter[true]
		'''.parse(resourceSet).assertNoErrors
	}
	
	private def makeBoardLibrary() {
		val resourceSet = resourceSetProvider.get
		val iotc = resourceSet.createResource(URI.createURI("resource/DeviceFactory/src/iot/boards/base_boards.iotc"))
		iotc.load(new StringInputStream('''
		package iot.boards
		define board esp32
			sensor barometer i2c(0x6D) as p
		'''), emptyMap)
		return resourceSet
	}
}