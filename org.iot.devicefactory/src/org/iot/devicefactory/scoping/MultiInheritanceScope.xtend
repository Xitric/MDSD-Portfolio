package org.iot.devicefactory.scoping

import com.google.common.base.Function
import com.google.common.collect.Iterables
import java.util.Collections
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope

import static extension org.iot.devicefactory.util.QualifiedNameUtils.*

class MultiInheritanceScopeUtil /*<T extends EObject> implements IScope*/ {

//	static def <T extends EObject> getQualifiedDescriptions(Iterable<IScope> parents, String containerName,
//		Function<T, QualifiedName> nameProvider) {
//		parents.allSimpleDescriptions.map[]
//	}
	
	static def getAllSimpleDescriptions(Iterable<IScope> scopes) {
		scopes.flatMap[
			allElements.filter[
				it.name.segmentCount === 1
			]
		]
	}
	
	static def getAllSingletonSimpleDescriptions(Iterable<IScope> scopes) {
		val allSimpleDescriptions = scopes.allSimpleDescriptions
		allSimpleDescriptions.filter[desc |
			allSimpleDescriptions.findFirst[name == desc.name] === allSimpleDescriptions.findLast[name == desc.name]
		]
	}
	
	static def getAllQualifiedDescriptions(Iterable<IScope> scopes, String containerName) {
		scopes.allSimpleDescriptions.map[
			EObjectDescription.create(it.name.prepend(containerName), it.EObjectOrProxy)
		]
	}

//	Iterable<IEObjectDescription> localScope
//	Iterable<IScope> parents
//
//	new(Iterable<T> localScope, Iterable<IScope> parents, String containerName, Function<T, QualifiedName> nameProvider) {
//		val simpleDescriptions = localScope.toObjectDescriptions(nameProvider)
//		val qualifiedDescriptions = localScope.toObjectDescriptions[getQualifiedName(containerName, nameProvider)]
//		
//		this.localScope = Iterables.concat(simpleDescriptions, qualifiedDescriptions)
//		this.parents = parents
//	}
//	
//	private def getQualifiedName(T obj, String containerName, Function<T, QualifiedName> nameProvider) {
//		val baseNameSegments = nameProvider.apply(obj).segments
//		val qualifiedSegments = Iterables.concat(Collections.singleton(containerName), baseNameSegments)
//		QualifiedName.create(qualifiedSegments)
//	}
//	
//	private def toObjectDescriptions(Iterable<T> objects, Function<T, QualifiedName> nameProvider) {
//		objects.map[
//			val name = nameProvider.apply(it)
//			name !== null ? EObjectDescription.create(name, it) : null
//		].filter[it !== null]
//	}
//	
//	override getAllElements() {
//		val parentElements = parents.flatMap[
//			allElements.filter[it.name.segmentCount === 1]
//		]
//		
//		null
//	}
//	
//	override getElements(QualifiedName name) {
//		throw new UnsupportedOperationException("TODO: auto-generated method stub")
//	}
//	
//	override getElements(EObject object) {
//		throw new UnsupportedOperationException("TODO: auto-generated method stub")
//	}
//	
//	override getSingleElement(QualifiedName name) {
//		throw new UnsupportedOperationException("TODO: auto-generated method stub")
//	}
//	
//	override getSingleElement(EObject object) {
//		throw new UnsupportedOperationException("TODO: auto-generated method stub")
//	}
//	
//	Iterable<EObject> localScope
//	
//	new(Iterable<EObject> localScope, Iterable<IScope> parents) {
//		this(localScope, [
//			IScope.NULLSCOPE
//		])
//	}
//	
//	new(Iterable<EObject> localScope, Provider<IScope> parentScopeProvider) {
//		super(parentScopeProvider.get(), false)
//		this.localScope = localScope
//	}
//	
//	override protected getAllLocalElements() {
//		
//	}
// TOOD: Isshadowed to remove FQN
}
