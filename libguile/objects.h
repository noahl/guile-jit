/* classes: h_files */

#ifndef SCM_OBJECTS_H
#define SCM_OBJECTS_H

/* Copyright (C) 1996,1999,2000,2001, 2003, 2006, 2008, 2009 Free Software Foundation, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA
 */



/* This file and objects.c contains those minimal pieces of the Guile
 * Object Oriented Programming System which need to be included in
 * libguile.
 *
 * {Objects and structs}
 *
 * Objects are currently based upon structs.  Although the struct
 * implementation will change thoroughly in the future, objects will
 * still be based upon structs.
 */

#include "libguile/__scm.h"
#include "libguile/struct.h"



/* {Class flags}
 *
 * These are used for efficient identification of instances of a
 * certain class or its subclasses when traversal of the inheritance
 * graph would be too costly.
 */
#define SCM_CLASS_FLAGS(class) (SCM_STRUCT_DATA (class) [scm_struct_i_flags])
#define SCM_OBJ_CLASS_FLAGS(obj) (SCM_STRUCT_VTABLE_DATA (obj) [scm_struct_i_flags])
#define SCM_SET_CLASS_FLAGS(c, f) (SCM_CLASS_FLAGS (c) |= (f))
#define SCM_CLEAR_CLASS_FLAGS(c, f) (SCM_CLASS_FLAGS (c) &= ~(f))
#define SCM_CLASSF_MASK SCM_STRUCTF_MASK

#define SCM_CLASSF_ENTITY	SCM_STRUCTF_ENTITY

#define SCM_I_ENTITYP(obj)\
	((SCM_OBJ_CLASS_FLAGS (obj) & SCM_CLASSF_ENTITY) != 0)
#define SCM_ENTITY_PROCEDURE(obj) \
        (SCM_PACK (SCM_STRUCT_DATA (obj) [scm_struct_i_procedure]))
#define SCM_SET_ENTITY_PROCEDURE(obj, v) \
        (SCM_STRUCT_DATA (obj) [scm_struct_i_procedure] = SCM_UNPACK (v))
#define SCM_ENTITY_SETTER(obj) (SCM_PACK (SCM_STRUCT_DATA (obj)[scm_struct_i_setter]))
#define SCM_SET_ENTITY_SETTER(obj, v) \
        (SCM_STRUCT_DATA (obj) [scm_struct_i_setter] = SCM_UNPACK (v))

#define SCM_SET_CLASS_DESTRUCTOR(c, d) SCM_SET_VTABLE_DESTRUCTOR (c, d)
#define SCM_SET_CLASS_INSTANCE_SIZE(c, s) \
  (SCM_STRUCT_DATA (c)[scm_struct_i_size] \
   = (SCM_STRUCT_DATA (c) [scm_struct_i_size] & SCM_STRUCTF_MASK) | s)

#define SCM_METACLASS_STANDARD_LAYOUT ""
struct scm_metaclass_standard {
  SCM layout;
  SCM vcell;
  SCM vtable;
  SCM print;
};

/* {Entity classes}
 *
 * For instances of entity classes (entities), the procedures to be
 * applied are stored in the instance itself.
 *
 * An example of an entity class is the class of generic methods.
 */
#define SCM_ENTITY_LAYOUT ""

/* {Interface to Goops}
 *
 * The evaluator contains a multi-method dispatch mechanism.
 * This interface is used by that mechanism and during creation of
 * smob and struct classes. 
 */

/* Internal representation of Goops objects. */
#define SCM_CLASSF_PURE_GENERIC (0x010 << 20)
#define SCM_CLASSF_GOOPS_VALID  (0x080 << 20)
#define SCM_CLASSF_GOOPS        (0x100 << 20)
#define scm_si_redefined         5
#define scm_si_hashsets          6
#define SCM_CLASS_OF(x)         SCM_STRUCT_VTABLE (x)
#define SCM_OBJ_CLASS_REDEF(x)  (SCM_PACK (SCM_STRUCT_VTABLE_DATA (x) [scm_si_redefined]))

typedef struct scm_effective_slot_definition {
  SCM name;
  long location;
  SCM init_value;
  SCM (*get) (SCM obj, SCM slotdef);
  SCM (*set) (SCM obj, SCM slotdef, SCM value);
} scm_effective_slot_definition;

#define SCM_ESLOTDEF(x) ((scm_effective_slot_definition *) SCM_CDR (x))

#define SCM_CMETHOD_CODE(cmethod) SCM_CDR (cmethod)
#define SCM_CMETHOD_FORMALS(cmethod) SCM_CAR (SCM_CMETHOD_CODE (cmethod))
#define SCM_CMETHOD_BODY(cmethod) SCM_CDR (SCM_CMETHOD_CODE (cmethod))
#define SCM_CMETHOD_ENV(cmethod)  SCM_CAR (cmethod)

/* Port classes */
#define SCM_IN_PCLASS_INDEX       0
#define SCM_OUT_PCLASS_INDEX      SCM_I_MAX_PORT_TYPE_COUNT
#define SCM_INOUT_PCLASS_INDEX    (2 * SCM_I_MAX_PORT_TYPE_COUNT)

/* Plugin proxy classes for basic types. */
SCM_API SCM scm_metaclass_standard;

/* Goops functions. */
SCM_API SCM scm_make_extended_class (char const *type_name, int applicablep);
SCM_INTERNAL void scm_i_inherit_applicable (SCM c);
SCM_API void scm_make_port_classes (long ptobnum, char *type_name);
SCM_API void scm_change_object_class (SCM, SCM, SCM);
SCM_API SCM scm_memoize_method (SCM x, SCM args);

SCM_API SCM scm_mcache_lookup_cmethod (SCM cache, SCM args);
SCM_API SCM scm_mcache_compute_cmethod (SCM cache, SCM args);
/* The following are declared in __scm.h
SCM_API SCM scm_call_generic_0 (SCM gf);
SCM_API SCM scm_call_generic_1 (SCM gf, SCM a1);
SCM_API SCM scm_call_generic_2 (SCM gf, SCM a1, SCM a2);
SCM_API SCM scm_apply_generic (SCM gf, SCM args);
*/
SCM_API SCM scm_call_generic_3 (SCM gf, SCM a1, SCM a2, SCM a3);
SCM_API SCM scm_entity_p (SCM obj);
SCM_API SCM scm_valid_object_procedure_p (SCM proc);
SCM_API SCM scm_set_object_procedure_x (SCM obj, SCM proc);
#ifdef GUILE_DEBUG
SCM_API SCM scm_object_procedure (SCM obj);
#endif
SCM_API SCM scm_make_class_object (SCM metaclass, SCM layout);
SCM_API SCM scm_make_subclass_object (SCM c, SCM layout);

SCM_INTERNAL SCM scm_i_make_class_object (SCM metaclass, SCM layout_string,
					  unsigned long flags);
SCM_INTERNAL void scm_init_objects (void);

#endif  /* SCM_OBJECTS_H */

/*
  Local Variables:
  c-file-style: "gnu"
  End:
*/
