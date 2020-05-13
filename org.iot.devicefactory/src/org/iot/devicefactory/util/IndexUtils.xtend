package org.iot.devicefactory.util

import com.google.inject.Inject
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.impl.ResourceDescriptionsProvider
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage

// Adapted from:
// https://github.com/LorenzoBettini/packtpub-xtext-book-examples/blob/master/org.example.smalljava/src/org/example/smalljava/scoping/SmallJavaIndex.xtend
class IndexUtils {

	@Inject ResourceDescriptionsProvider resourceDescriptionsProvider
	@Inject IContainer.Manager containerManager

	def getVisibleContainers(EObject context) {
		val resource = context.eResource
		val descriptions = resourceDescriptionsProvider.getResourceDescriptions(resource)
		val description = descriptions.getResourceDescription(resource.URI)
		if (description !== null) {
			containerManager.getVisibleContainers(description, descriptions)
		} else {
			emptyList
		}
	}

	def getVisibleDescriptions(EObject context, EClass type) {
		context.visibleContainers.map[it.getExportedObjectsByType(type)].flatten
	}
	
	def getVisibleBoards(EObject context) {
		context.getVisibleDescriptions(DeviceLibraryPackage.Literals.BOARD)
	}
}
