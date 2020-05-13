package org.iot.devicefactory.util

import org.eclipse.emf.ecore.EObject
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.common.VariableDeclaration
import org.iot.devicefactory.common.Variables

import static extension java.util.Collections.*
import static extension org.eclipse.xtext.EcoreUtil2.*

class CommonUtils {
	
	static def Iterable<Variable> getVariables(VariableDeclaration variableDeclaration) {
		switch variableDeclaration {
			Variable: variableDeclaration.singleton
			Variables: variableDeclaration.vars
		}
	}
	
	static def Iterable<Variable> getVariables(Pipeline pipeline) {
		pipeline.eAllOfType(Map).last?.output?.variables ?: emptyList
	}
	
	static def Iterable<Variable> getVariables(EObject context) {
		context.getContainerOfType(Pipeline)?.eContainer()?.getContainerOfType(Map)?.output?.variables ?: emptyList
	}
}
