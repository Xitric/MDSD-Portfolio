/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.validation

import com.google.inject.Inject
import java.util.HashMap
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.validation.Check
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition
import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.I2C
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.deviceLibrary.OverrideSensorDefinition
import org.iot.devicefactory.deviceLibrary.Pin
import org.iot.devicefactory.deviceLibrary.SensorDefinition
import org.iot.devicefactory.scoping.DeviceLibraryScopeProvider

import static org.iot.devicefactory.validation.DeviceLibraryIssueCodes.*

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.CommonUtils.*
import static extension org.iot.devicefactory.util.DeviceLibraryUtils.*

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class DeviceLibraryValidator extends AbstractDeviceLibraryValidator {
	
	@Inject DeviceLibraryScopeProvider scopeProvider
	
	@Check
	def validatePackage(Library library) {
		val segments = library.eResource.URI.segments
		
		if (segments.get(0) != "resource" || segments.get(2) != "src") {
			error(
				"A board library must be located inside the src folder of an Eclipse project",
				Literals.LIBRARY__NAME
			)
		} else if(segments.length == 4) {
			if (library.name !== null) {
				error(
					"There cannot be a package declaration in library files located outside a package",
					Literals.LIBRARY__NAME,
					ILLEGAL_PACKAGE
				)
			}
		} else {
			val expectedPackage = segments.subList(3, segments.length - 1).join(".")
			if (library.name != expectedPackage) {
				error(
					'''Incorrect package name, expected «expectedPackage»''',
					Literals.LIBRARY__NAME,
					INCORRECT_PACKAGE,
					expectedPackage
				)
			}
		}
	}
	
	@Check
	def validateNoDuplicateBoards(Board board) {
		val library = board.getContainerOfType(Library)
		if (library.boards.takeWhile[it !== board].exists[name == board.name]) {
			error("Duplicate board names are not allowed. Choose a unique name", Literals.BOARD__NAME)
		}
	}
	
	@Check
	def validateNoDuplicateSensors(SensorDefinition sensor) {
		val board = sensor.getContainerOfType(Board)
		if (board.sensors.takeWhile[it !== sensor].exists[it.name == sensor.name]) {
			val feature = switch sensor {
				BaseSensorDefinition: Literals.BASE_SENSOR_DEFINITION__NAME
				OverrideSensorDefinition: Literals.OVERRIDE_SENSOR_DEFINITION__PARENT
			}
			
			error('''Duplicate sensor definition «sensor.name» in same board''', feature, DUPLICATE_SENSOR)
		}
	}
	
	@Check
	def validateChildSensorsOverride(BaseSensorDefinition sensor) {
		val sensorScope = scopeProvider.getScope(sensor, Literals.OVERRIDE_SENSOR_DEFINITION__PARENT)
		val allSensors = sensorScope.allElements.map[name.lastSegment]
		if (allSensors.exists[it == sensor.name]) {
			error(
				'''Redeclared sensor «sensor.name» must override inherited definition from parent''',
				Literals.BASE_SENSOR_DEFINITION__NAME,
				NON_OVERRIDING_SENSOR
			)
		}
	}
	
	@Check
	def validateAmbiguousInheritance(Board board) {
		val sensorScope = scopeProvider.getScope(board, Literals.OVERRIDE_SENSOR_DEFINITION__PARENT)
		val allSensors = sensorScope.allElements
		val visited = new HashMap<String, URI>
		
		for (IEObjectDescription desc: allSensors) {
			val uri = desc.EObjectURI
			val name = desc.name.lastSegment
			if (visited.get(name) !== null && visited.get(name) != uri) {
				if (! board.sensors.filter(OverrideSensorDefinition).exists[it.name == name]) {
					error(
						'''Sensor with identifier «name» refers to multiple inherited definitions. Resolve this ambiguity by explicitly overriding one of them''',
						Literals.BOARD__NAME,
						INHERITANCE_CONFLICT
					)
					return
				}
			}
			visited.put(name, uri)
		}
	}
	
	@Check
	def validatePreprocessWhenRequired(OverrideSensorDefinition sensor) {
		if (sensor.preprocess !== null) {
			return
		}
		
		val sensorScope = scopeProvider.getScope(sensor, Literals.OVERRIDE_SENSOR_DEFINITION__PARENT)
		val sensorsByName = sensorScope.allElements.filter[
			name.lastSegment == sensor.parent.name
		].groupBy[EObjectURI]
		
		if (sensorsByName.size === 1) {
			error(
				'''A preprocess step is required on overrides that do not resolve a conflict due to multiple inheritance''',
				Literals.SENSOR_DEFINITION__PREPROCESS,
				REQUIRED_PREPROCESS
			)
		}
	}
	
	@Check
	def validateNoDuplicateIncludes(Board board) {
		if (board.parents.size < 2) {
			return
		}
		
		for (var i = 1; i < board.parents.size; i++) {
			val parent = board.parents.get(i)
			if (board.parents.subList(0, i).exists[it.name == parent.name]) {
				error(
					'''«parent.name» appears multiple times in includes statement''',
					Literals.BOARD__PARENTS,
					DeviceLibraryIssueCodes.DUPLICATE_INCLUDE
				)
				return
			}
		}
	}
	
	@Check
	def validateSensorVariableDeclaration(BaseSensorDefinition sensor) {
		val input = sensor.input
		if (input instanceof I2C) {
			return
		}
		
		val actualCount = sensor.input.variables.variableCount
		val expectedCount = switch input {
			Pin: input.pins.size
			default: 1
		}
		
		if (expectedCount !== actualCount) {
			error(
				'''Expected variable declaration to contain «expectedCount» variable«IF expectedCount > 1»s«ENDIF», got «actualCount»''',
				Literals.BASE_SENSOR_DEFINITION__INPUT,
				INCORRECT_VARIABLE_DECLARATION
			)
		}
	}
}
