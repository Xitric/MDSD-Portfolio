package org.iot.devicefactory.scoping

import com.google.common.collect.Iterables
import java.util.ArrayList
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.impl.SimpleScope
import org.iot.devicefactory.deviceLibrary.Board

import static extension org.iot.devicefactory.util.DeviceLibraryUtils.*
import static extension org.iot.devicefactory.util.QualifiedNameUtils.*

class MultiInheritanceScopingUtil {
	
	// TODO: we can skip some logic if we only have one parent
	static def IScope getBoardSensorScope(Board board) {
		// Get all inherited definitions, possible with duplicate elements
		// Consists of both simple and qualified names from each parent
		val parentScopes = board.parents.map[boardSensorScope].flatMap[allElements]
		
		// Remove qualified names and duplicates from parents
		// Removing duplicates is not an issue, since clients are expected to
		// override duplicate definitions locally
		val filteredParentScope = parentScopes.filter[ desc |
			desc.name.segmentCount == 1 &&
			parentScopes.findFirst[name == desc.name].EObjectURI == parentScopes.findLast[name == desc.name].EObjectURI
		]
		
		// Add prefix to names inherited from parents
		val qualifiedParentScope = filteredParentScope.map[EObjectDescription.create(
			it.name.prepend(board.name),
			it.EObjectOrProxy
		)]
		val outerScope = new SimpleScope(Iterables.concat(filteredParentScope, qualifiedParentScope))
		
		// Create scope with simple and qualified names for all locally defined
		// sensors
		val localSensors = board.sensors.filter[name !== null]
		val localSimpleScope = localSensors.map[EObjectDescription.create(name, it)]
		val localQualifiedScope = localSensors.map[EObjectDescription.create(
			QualifiedName.create(board.name, name),
			it
		)]
		val localScope = Iterables.concat(localSimpleScope, localQualifiedScope)
		
		// Return a scope where local definitions shadow inherited definitions
		new SimpleScope(outerScope, localScope)
	}
	
	static def Iterable<IEObjectDescription> removeDuplicates(Iterable<IEObjectDescription> objectDescriptions) {
		val result = new ArrayList<IEObjectDescription>()
		for (IEObjectDescription desc: objectDescriptions) {
			if (! result.exists[name == desc.name && EObjectURI == desc.EObjectURI]) {
				result.add(desc)
			}
		}
		return result
	}
}
