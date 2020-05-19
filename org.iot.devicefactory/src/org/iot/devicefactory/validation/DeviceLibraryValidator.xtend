/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.validation

import org.eclipse.xtext.validation.Check
import org.iot.devicefactory.deviceLibrary.BaseSensor
import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.I2C
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.deviceLibrary.Pin
import org.iot.devicefactory.deviceLibrary.Sensor

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
	
	@Check
	def validatePackage(Library library) {
		val segments = library.eResource.URI.segments
		
		if (segments.get(0) != "resource" || segments.get(2) != "src") {
			error("A board library must be located inside the src folder of an Eclipse project", Literals.LIBRARY__NAME)
		} else if(segments.length == 4) {
			if (library.name !== null) {
				error("There cannot be a package declaration in library files located outside a package", Literals.LIBRARY__NAME, ILLEGAL_PACKAGE)
			}
		} else {
			val expectedPackage = segments.subList(3, segments.length - 1).join(".")
			if (library.name != expectedPackage) {
				error('''Incorrect package name, expected «expectedPackage»''', Literals.LIBRARY__NAME, INCORRECT_PACKAGE, expectedPackage)
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
	def validateNoDuplicateSensors(Sensor sensor) {
		val board = sensor.getContainerOfType(Board)
		if (board.sensors.takeWhile[it !== sensor].exists[it.name == sensor.name]) {
			val feature = switch sensor {
				BaseSensor: Literals.BASE_SENSOR__NAME
				OverrideSensor: Literals.OVERRIDE_SENSOR__PARENT
			}
			
			error('''Duplicate sensor definition «sensor.name» in same board''', feature, DUPLICATE_SENSOR)
		}
	}
	
	@Check
	def validateChildSensorsOverride(BaseSensor sensor) {
		val board = sensor.getContainerOfType(Board)
		if (board.parent.boardHierarchy.exists[sensors.exists[name == sensor.name]]) {
			error('''Redeclared sensor «sensor.name» must override inherited definition from parent''',
				Literals.BASE_SENSOR__NAME, NON_OVERRIDING_SENSOR
			)
		}
	}
	
	@Check
	def validateSensorVariableDeclaration(BaseSensor sensor) {
		val input = sensor.input
		val expectedCount = switch input {
			Pin: input.pins.size
			I2C: 1
		}
		
		val actualCount = sensor.input.variables.variableCount
		
		if (expectedCount !== actualCount) {
			error(
				'''Expected variable declaration to contain «expectedCount» variable«IF expectedCount > 1»s«ENDIF», got «actualCount»''',
				Literals.BASE_SENSOR__INPUT,
				INCORRECT_VARIABLE_DECLARATION
			)
		}
	}
}
