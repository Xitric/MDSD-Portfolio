package org.iot.devicefactory.util

import com.google.inject.Inject
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.impl.ResourceDescriptionsProvider

class DeviceFactoryUtils {
	
	@Inject ResourceDescriptionsProvider resourceDescriptionsProvider
	@Inject IContainer.Manager containerManager
	
	static def matches(QualifiedName me, QualifiedName other) {
		val meSkipped = me.lastSegment == "*" ? me.skipLast(1) : me 
		
		if (meSkipped.segmentCount > other.segmentCount) {
			return false
		}
		
		for (var i = 0; i < meSkipped.segmentCount; i++) {
			if (meSkipped.getSegment(i) != other.getSegment(i)) {
				return false
			}
		}
		
		return true
	}
	
	// Adapted from:
	// https://github.com/LorenzoBettini/packtpub-xtext-book-examples/blob/master/org.example.smalljava/src/org/example/smalljava/scoping/SmallJavaIndex.xtend
	def getVisibleDescriptions(EObject context, EClass type) {
		context.visibleContainers.map[it.getExportedObjectsByType(type)].flatten
	}
	
	def getVisibleContainers(EObject context) {
		val resource = context.eResource
		val descriptions = resourceDescriptionsProvider.getResourceDescriptions(resource)
		val description = descriptions.getResourceDescription(resource.URI)
		if (description !== null) {
			return containerManager.getVisibleContainers(description, descriptions)
		} else {
			return emptyList
		}
	}
}