/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class DeviceLibraryStandaloneSetup extends DeviceLibraryStandaloneSetupGenerated {

	def static void doSetup() {
		new DeviceLibraryStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
