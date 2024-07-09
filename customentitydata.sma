#include <amxmodx>
#include <fakemeta>
// #include <ced>
// #include <customentdata>
// #include <cedlist>
#include <reapi>


// native ced_register_key(DataType:dataType, key, handler[]);

// native any:ced_set(entity, DataType:dataType, key, any:...);
// native any:ced_get(entity, DataType:dataType, key, any:...);
// native bool:ced_exists(entity, DataType:dataType, key);
// native ced_reset(entity, DataType:dataType, key);

// forward ced_integer_data_change_post(entity, key, oldValue, newValue);
// forward ced_float_data_change_post(entity, key, Float:oldValue, Float:newValue);
// forward ced_string_data_change_post(entity, key, oldValue[], newValue[]);
// forward ced_vector_data_change_post(entity, key, Float:oldValue[3], Float:newValue[3]);

// forward ced_data_clear_pre(entity);
// forward ced_data_clear_post(entity);


enum DataType { 
    ced_int = 0, 
    ced_float, 
    ced_string, 
    ced_vec,
};

enum eForwards {
	eForward_IntChange,
	eForward_FloatChange,
	eForward_StringChange,
	eForward_VecChange,

	eForward_ClearDataPre,
	eForward_ClearDataPost,
}

new Trie:g_aTrie;
new g_Forward[eForwards], g_fwDummyResult;

public plugin_init()
{
	RegisterHookChain(RH_ED_Free, "fw_Edict_Free");
}

public plugin_natives()
{	g_aTrie = TrieCreate();

	register_library("custom_entity_data");
	register_native("set_ced", "native_set_ced");
	register_native("get_ced", "native_get_ced");
	register_native("ced_set", "native_set_ced");
	register_native("ced_get", "native_get_ced");
	register_native("ced_exists", "native_ced_exists");
	register_native("ced_reset", "native_ced_reset");


	g_Forward[eForward_IntChange] = CreateMultiForward("ced_integer_data_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	g_Forward[eForward_FloatChange] = CreateMultiForward("ced_float_data_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	g_Forward[eForward_StringChange] = CreateMultiForward("ced_string_data_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING, FP_STRING);
	g_Forward[eForward_VecChange] = CreateMultiForward("ced_vector_data_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_ARRAY, FP_ARRAY);
	
	g_Forward[eForward_ClearDataPre] = CreateMultiForward("ced_data_clear_pre", ET_IGNORE, FP_CELL);
	g_Forward[eForward_ClearDataPost] = CreateMultiForward("ced_data_clear_post", ET_IGNORE, FP_CELL);
}

public native_set_ced()
{
	new ent = get_param(1);

	if (is_nullent(ent)) {
		return false;
	}

	new szKey[64], iKeySize = sizeof(szKey);
	new iType = get_param(2);

	formatex(szKey, iKeySize, "%d_%d_%d", ent, iType, get_param(3));

	/************* Код для удаления инфы после смерти объекта ********** */
	new Array:aExistingKeys, szKeys[16];

	formatex(szKeys, charsmax(szKeys), "%d_keys", ent);
	if (TrieKeyExists(g_aTrie, szKeys)) {
		TrieGetCell(g_aTrie, szKeys, aExistingKeys);
	}
	else {
		aExistingKeys = ArrayCreate(64, 1);
		TrieSetCell(g_aTrie, szKeys, aExistingKeys);
	}


	/************* Код для удаления инфы после смерти объекта ********** */

	switch (iType) {
		case ced_int: {
			
			new iValue = get_param_byref(4);
			new iOldValue;

			if (TrieKeyExists(g_aTrie, szKey)) {
				
				TrieGetCell(g_aTrie, szKey, iOldValue);
				ExecuteForward(g_Forward[eForward_IntChange], g_fwDummyResult, ent, ced_int, iOldValue, iValue);
			}
			else {
				// Пушим ключ для удаления инфы при смерти объекта
				ArrayPushString(aExistingKeys, szKey);
			}
			
			TrieSetCell(g_aTrie, szKey, iValue);
			return true;
		}
    	case ced_float: {

			new Float:flValue = get_param_f(4);
			new Float:flOldValue;
	
			if (TrieKeyExists(g_aTrie, szKey)) {
				
				TrieGetCell(g_aTrie, szKey, flOldValue);			
				ExecuteForward(g_Forward[eForward_FloatChange], g_fwDummyResult, ent, ced_float, flOldValue, flValue);
			}
			else {
				// Пушим ключ для удаления инфы при смерти объекта
				ArrayPushString(aExistingKeys, szKey);
			}
			
			TrieSetCell(g_aTrie, szKey, flValue);
			return true;
		} 
    	case ced_string: {

			new szValue[256]; get_string(4, szValue, sizeof(szValue));
			new szOldValue[256], iSize = sizeof(szValue);

			if (TrieKeyExists(g_aTrie, szKey)) {
				TrieGetString(g_aTrie, szKey, szOldValue, iSize);
				ExecuteForward(g_Forward[eForward_StringChange], g_fwDummyResult, ent, ced_string, szOldValue, szValue);
			}
			else {
				// Пушим ключ для удаления инфы при смерти объекта
				ArrayPushString(aExistingKeys, szKey);
			}

			TrieSetString(g_aTrie, szKey, szValue);

			return true;
		} 
    	case ced_vec: {

			new Float:vecArray[3]; 
			new Float:vecOldArray[3]; 
			get_array_f(4, vecArray, sizeof(vecArray));

			if (TrieKeyExists(g_aTrie, szKey)) {
				
				TrieGetString(g_aTrie, szKey, any:vecOldArray, 3);
				ExecuteForward(g_Forward[eForward_VecChange], g_fwDummyResult, ent, ced_vec, PrepareArray(any:vecOldArray, 3), PrepareArray(any:vecArray, 3));
			}
			else {
				// Пушим ключ для удаления инфы при смерти объекта
				ArrayPushString(aExistingKeys, szKey);
			}

			TrieSetString(g_aTrie, szKey, any:vecArray);
			return true;
		}
	}

	return false;
}

public any:native_get_ced()
{
	new ent = get_param(1);

	if (is_nullent(ent)) {
		return false;
	}

	new iType = get_param(2);
	new szKey[32];
	formatex(szKey, charsmax(szKey), "%d_%d_%d", ent, iType, get_param(3));

	switch (iType) {
		case ced_int: {
			new iValue;

			if (TrieKeyExists(g_aTrie, szKey)) {

				TrieGetCell(g_aTrie, szKey, iValue);
				// server_print("Return value = %d", iValue);
				return iValue;
			}

			return false;
		}
    	case ced_float: {

			new Float:flValue;

			if (TrieKeyExists(g_aTrie, szKey)) {
				TrieGetCell(g_aTrie, szKey, flValue);
				return flValue;
			}

			return 0.0;
		} 
    	case ced_string: {

			new szValue[256]; 
			
			if (TrieKeyExists(g_aTrie, szKey)) {
				new iSize = get_param_byref(5);

				TrieGetString(g_aTrie, szKey, szValue, iSize);
				set_string(4, szValue, iSize);
				return true;
			}

			return false;
		} 
    	case ced_vec: {

			new Float:vecArray[3]; 

			if (TrieKeyExists(g_aTrie, szKey)) {

				TrieGetString(g_aTrie, szKey, any:vecArray, 3);
				set_array_f(4, vecArray, 3);
				return true;
			}

			return false;
		}
	}

	return false;
}

public native_ced_exists()
{
	new ent = get_param(1);

	if (is_nullent(ent)) {
		return false;
	}

	new iType = get_param(2);
	new szKey[32];
	formatex(szKey, charsmax(szKey), "%d_%d_%d", ent, iType, get_param(3));

	return TrieKeyExists(g_aTrie, szKey);
}

public native_ced_reset()
{
	new ent = get_param(1);

	if (is_nullent(ent)) {
		return false;
	}

	new iType = get_param(2);
	new szKey[32];
	formatex(szKey, charsmax(szKey), "%d_%d_%d", ent, iType, get_param(3));

	if (TrieKeyExists(g_aTrie, szKey)) {

		new Array:aExistingKeys, szKeys[16];
		TrieGetCell(g_aTrie, fmt("%d_keys", szKey), aExistingKeys);

		for (new i; i<ArraySize(aExistingKeys); i++) {
			ArrayGetString(aExistingKeys, i, szKeys, charsmax(szKeys));

			if (equali(szKeys, szKey)) {
				ArrayDeleteItem(aExistingKeys, i--);
			}
		}

		TrieDeleteKey(g_aTrie, szKey);
		return true;
	}

	return false;
}

public fw_Edict_Free(iEnt)
{
	if (!is_nullent(iEnt)) {
		new szKey[32];

		formatex(szKey, charsmax(szKey), "%d_keys", iEnt);
		ExecuteForward(g_Forward[eForward_ClearDataPre], g_fwDummyResult, iEnt);
		if (TrieKeyExists(g_aTrie, szKey)) {
			new Array:aExistingKeys;

			TrieGetCell(g_aTrie, "%d_keys", aExistingKeys);

			if (aExistingKeys != Invalid_Array) {

				new szLowerKeys[64];
				for (new i; i<ArraySize(aExistingKeys); i++) {
					ArrayGetString(aExistingKeys, i, szLowerKeys, charsmax(szLowerKeys));

					if (TrieKeyExists(g_aTrie, szLowerKeys)) {
						TrieDeleteKey(g_aTrie, szLowerKeys);
					}
				}

				ArrayDestroy(aExistingKeys);
			} 
		}

		ExecuteForward(g_Forward[eForward_ClearDataPost], g_fwDummyResult, iEnt);
	}
}