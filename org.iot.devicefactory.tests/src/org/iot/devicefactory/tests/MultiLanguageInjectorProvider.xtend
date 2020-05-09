package org.iot.devicefactory.tests

class MultiLanguageInjectorProvider extends DeviceFactoryInjectorProvider {
	
	override protected internalCreateInjector() {
		new DeviceLibraryInjectorProvider().getInjector
		return super.internalCreateInjector
	}
}