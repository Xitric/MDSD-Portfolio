/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.validation

import com.google.inject.Inject
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.validation.CheckType
import org.iot.devicefactory.deviceFactory.BaseSensor
import org.iot.devicefactory.deviceFactory.Channel
import org.iot.devicefactory.deviceFactory.Data
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceFactory.DeviceFactoryPackage.Literals
import org.iot.devicefactory.deviceFactory.Language
import org.iot.devicefactory.deviceFactory.Library
import org.iot.devicefactory.deviceFactory.OverrideSensor
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.SensorDataOut
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage
import org.iot.devicefactory.generator.DeviceFactoryGenerator
import org.iot.devicefactory.typing.DeviceFactoryTypeChecker
import org.iot.devicefactory.util.IndexUtils

import static org.iot.devicefactory.validation.DeviceFactoryIssueCodes.*

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class DeviceFactoryValidator extends AbstractDeviceFactoryValidator {
	
	//TODO: Better utilities for navigating EMF model - good for generator, and can be explained in the report 
	
	@Inject DeviceFactoryGenerator factoryGenerator
	@Inject extension IndexUtils
	@Inject extension IQualifiedNameConverter 
	@Inject extension DeviceFactoryTypeChecker
	
	@Check(CheckType.NORMAL)
	def validateDeployment(Deployment deployment) {
		if (deployment.channels.empty) {
			error("There must be at least one channel", Literals.DEPLOYMENT__CHANNELS, MISSING_CHANNEL)
		}
		
		if (deployment.devices.empty) {
			error("There must be at least one device", Literals.DEPLOYMENT__DEVICES, MISSING_DEVICE)
		}
		
		if (deployment.fog.size > 1) {
			error("There can be at most one fog", Literals.DEPLOYMENT__FOG, AMBIGUOUS_FOG)
		}
		
		if (deployment.cloud.size == 0) {
			error("There must be a cloud", Literals.DEPLOYMENT__FOG, MISSING_CLOUD)
		}
		
		if (deployment.cloud.size > 1) {
			error("There can be at most one cloud", Literals.DEPLOYMENT__FOG, AMBIGUOUS_CLOUD)
		}
	}
	
	@Check(CheckType.NORMAL)
	def validateImport(Library library) {
		val visibleBoards = library.getVisibleDescriptions(DeviceLibraryPackage.Literals.BOARD)
		val importQualifiedName = library.importedNamespace.toQualifiedName
		
		if (! visibleBoards.exists[importQualifiedName.matches(qualifiedName)]) {
			error(
				'''No resource found with qualified name «library.importedNamespace»''',
				Literals.LIBRARY__IMPORTED_NAMESPACE,
				SUPERFLUOUS_LIBRARY
			)
		} else if (importQualifiedName.segmentCount == 1) {
			warning(
				'''Unnecessary import of library «library.importedNamespace» has no effect''',
				Literals.LIBRARY__IMPORTED_NAMESPACE,
				SUPERFLUOUS_LIBRARY
			)
		}
	}
	
	@Check
	def validateLanguage(Language language) {
		if (! factoryGenerator.supportedLanguages.contains(language.name)) {
			error('''Unsupported language «language.name»''', Literals.LANGUAGE__NAME, UNSUPPORTED_LANGUAGE)
		}
	}
	
	@Check
	def validateOutTypes(SensorDataOut output) {
		val expectedType = output.getContainerOfType(Data).typeOf
		val actualType = output.typeOf
		
		if (actualType != expectedType) {
			error(
				'''Incorrect output type from data pipeline. Expected «expectedType», got «actualType»''',
				Literals.SENSOR_DATA_OUT__PIPELINE,
				INCORRECT_OUT_TYPE
			)
		}
	}
	
	@Check
	def validateLegalOverride(OverrideSensor sensor) {
		if (sensor.sensorHierarchy.size == 1) {
			error('''No such sensor «sensor.definition.name» to override from parent''',
				Literals.SENSOR__DEFINITION, ILLEGAL_OVERRIDE
			)
		}
	}
	
	@Check
	def validateChildSensorsOverride(BaseSensor sensor) {
		if (sensor.sensorHierarchy.size > 1) {
			error('''Redeclared sensor «sensor.definition.name» must override inherited definition from parent''',
				Literals.SENSOR__DEFINITION, MISSING_OVERRIDE
			)
		}
	}
	
	@Check
	def validateChannel(Channel channel) {
		val deployment = channel.getContainerOfType(Deployment)
		if (deployment.channels.takeWhile[it !== channel].exists[name == channel.name]) {
			error('''Duplicate channel «channel.name»''', Literals.CHANNEL__NAME, DUPLICATE_CHANNEL)
		}
	}
	
	@Check
	def validateDevice(Device device) {
		val deployment = device.getContainerOfType(Deployment)
		if (deployment.devices.takeWhile[it !== device].exists[name == device.name]) {
			error('''Duplicate device «device.name»''', Literals.DEVICE__NAME, DUPLICATE_DEVICE)
		}
	}
	
	@Check
	def validateSensor(Sensor sensor) {
		val device = sensor.getContainerOfType(Device)
		if (device.sensors.takeWhile[it !== sensor].exists[definition === sensor.definition]) {
			error('''Duplicate sensor definition «sensor.definition.name» in same device''', Literals.SENSOR__DEFINITION, DUPLICATE_SENSOR)
		}
	}
	
	@Check
	def validateData(Data data) {
		val sensor = data.getContainerOfType(Sensor)
		if (sensor.datas.takeWhile[it !== data].exists[name == data.name]) {
			error('''Duplicate data «data.name» in same sensor''', Literals.DATA__NAME, DUPLICATE_DATA)
		}
	}
}
