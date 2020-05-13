/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.scoping

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.iot.devicefactory.common.CommonPackage
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.deviceLibrary.Sensor

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.CommonUtils.*
import static extension org.iot.devicefactory.util.DeviceLibraryUtils.*

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class DeviceLibraryScopeProvider extends AbstractDeviceLibraryScopeProvider {
	
	override getScope(EObject context, EReference reference) {
		switch reference {
			case Literals.BOARD__PARENT:
				context.boardParentScope
			case CommonPackage.Literals.REFERENCE__VARIABLE:
				context.referenceVariableScope
			default:
				super.getScope(context, reference)
		}
	}
	
	private def IScope getBoardParentScope(EObject context) {
		val library = context.getContainerOfType(Library)
		Scopes.scopeFor(library.boards.takeWhile[it !== context])
	}
	
	private def IScope getReferenceVariableScope(EObject context) {
		val expressionScope = context.variables
		if (expressionScope.empty) {
			val sensor = context.getContainerOfType(Sensor)
			Scopes.scopeFor(sensor.internalVariables)
		} else {
			Scopes.scopeFor(expressionScope)
		}
	}
}
