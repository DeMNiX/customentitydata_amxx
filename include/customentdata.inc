#if defined _customentdata_included
    #endinput
#endif
#define _customentdata_included

#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib custom_entity_data
#endif

#define set_ced         ced_set
#define get_ced         ced_get

enum DataType { 
    ced_int = 0, 
    ced_float, 
    ced_string, 
    ced_vec,
};

native ced_register_key(DataType:dataType, key, handler[]);

native any:ced_set(entity, DataType:dataType, key, any:...);
native any:ced_get(entity, DataType:dataType, key, any:...);
native bool:ced_exists(entity, DataType:dataType, key);
native ced_reset(entity, DataType:dataType, key);

forward ced_integer_data_change_post(entity, key, oldValue, newValue);
forward ced_float_data_change_post(entity, key, Float:oldValue, Float:newValue);
forward ced_string_data_change_post(entity, key, oldValue[], newValue[]);
forward ced_vector_data_change_post(entity, key, Float:oldValue[3], Float:newValue[3]);

forward ced_data_clear_pre(entity);
forward ced_data_clear_post(entity);
