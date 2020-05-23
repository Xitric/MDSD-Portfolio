package org.iot.devicefactory.generator.python

import com.google.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.generator.LanguageGenerator
import org.iot.devicefactory.generator.python.device.BoardGenerator
import org.iot.devicefactory.generator.python.device.CompositionRootGenerator
import org.iot.devicefactory.generator.python.device.DeviceGenerator
import org.iot.devicefactory.generator.python.device.MainGenerator
import org.iot.devicefactory.generator.python.device.SensorGenerator

import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class PythonGenerator implements LanguageGenerator {

	@Inject CompositionRootGenerator compositionRootGenerator
	@Inject DeviceGenerator deviceGenerator
	@Inject SensorGenerator sensorGenerator
	@Inject BoardGenerator boardGenerator
	@Inject MainGenerator mainGenerator

	override getLanguage() {
		"python"
	}

	override generate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		resource.allContents.filter(Device).forEach[generateDevice(fsa)]
		
		// TODO: Generate fog and cloud
	}

	private def void generateDevice(Device device, IFileSystemAccess2 fsa) {
		val basePath = '''device/«device.name.asModule»'''

		var env = new GeneratorEnvironment()
		fsa.generateFile(
			'''«basePath»/composition_root.py''',
			compositionRootGenerator.compile(device, env)
		)

		env = new GeneratorEnvironment(env.libFiles)
		fsa.generateFile(
			'''«basePath»/«device.name.asModule».py''',
			deviceGenerator.compile(device, env)
		)

		for (Sensor sensor : device.sensors) {
			env = new GeneratorEnvironment(env.libFiles)
			fsa.generateFile(
				'''«basePath»/«sensor.name.asModule».py''',
				sensorGenerator.compile(sensor, env)
			)
		}
		
		env = new GeneratorEnvironment(env.libFiles)
		fsa.generateFile(
			'''«basePath»/«device.board.name.asModule».py''',
			boardGenerator.compile(device.board, env)
		)

		if (fsa.isFile('''«basePath»/main.py''')) {
			val mainContents = fsa.readTextFile('''«basePath»/main.py''')
			fsa.generateFile('''«basePath»/main.py''', mainContents)
		} else {
			fsa.generateFile('''«basePath»/main.py''', mainGenerator.compile(device))
		}

		for (String libFile : env.libFiles) {
			("/libfiles/" + libFile).compileAsLibfile(fsa, device)
		}
	}

	private def compileAsLibfile(String path, IFileSystemAccess2 fsa, Device device) {
		try (val stream = class.getResourceAsStream(path)) {
			val fileName = path.replaceFirst("/libfiles/", "")
			fsa.generateFile('''device/«device.name.asModule»/«fileName»''', stream)
		}
	}
}
