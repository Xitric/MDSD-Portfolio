package org.iot.devicefactory.scoping

import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.common.VariableDeclaration
import org.iot.devicefactory.common.Variables

import static extension java.util.Collections.*
import static extension org.eclipse.xtext.EcoreUtil2.*

class CommonScopingUtils {
	
	static def Iterable<Variable> getVariables(VariableDeclaration variableDeclaration) {
		switch variableDeclaration {
			Variable: variableDeclaration.singleton
			Variables: variableDeclaration.vars
		}
	}
	
	static def Iterable<Variable> getVariables(Pipeline pipeline) {
		val lastMap = pipeline.eAllOfType(Map).last
		lastMap === null ? EMPTY_SET : lastMap.output.variables
	}
}
