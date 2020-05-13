package org.iot.devicefactory.validation

interface DeviceLibraryIssueCodes {
	val ISSUE_PREFIX = "org.iot.devicefactory.deviceLibrary."
	
	val ILLEGAL_PACKAGE = ISSUE_PREFIX + "ILLEGAL_PACKAGE"
	val INCORRECT_PACKAGE = ISSUE_PREFIX + "INCORRECT_PACKAGE"
	val DUPLICATE_SENSOR = ISSUE_PREFIX + "DUPLICATE_SENSOR"
	val NON_OVERRIDING_SENSOR = ISSUE_PREFIX + "NON_OVERRIDING_SENSOR"
}