namespace System.Reflection
{
	static class Convert
	{
		static (Type type, void* ptr) GetTypeAndPointer(Object obj)
		{
			var objType = obj.RawGetType();
			void* dataPtr = (uint8*)Internal.UnsafeCastToPtr(obj) + objType.mMemberDataOffset;
			if (objType.IsBoxed)
				objType = objType.UnderlyingType;
			if (objType.IsTypedPrimitive)
				objType = objType.UnderlyingType;
			return (objType, dataPtr);
		}

		public static Result<int64> ToInt64(Object obj)
		{
			var (objType, dataPtr) = GetTypeAndPointer(obj);
			switch (objType.mTypeCode)
			{
			case .Int8: return (.)*(int8*)dataPtr;
			case .Int16: return (.)*(int16*)dataPtr;
			case .Int32: return (.)*(int32*)dataPtr;
			case .Int64: return (.)*(int64*)dataPtr;
			case .UInt8, .Char8: return (.)*(uint8*)dataPtr;
			case .UInt16, .Char16: return (.)*(uint16*)dataPtr;
			case .UInt32, .Char32: return (.)*(uint32*)dataPtr;
			case .UInt64: return (.)*(uint64*)dataPtr;
			case .Int: return (.)*(int*)dataPtr;
			case .UInt: return (.)*(uint*)dataPtr;
			default: return .Err;
			}
		}

		public static bool IntCanFit(int64 val, Type type)
		{
			switch (type.mTypeCode)
			{
			case .Int8: return (val >= -0x80) && (val <= 0x7F);
			case .Int16: return (val >= -0x8000) && (val <= 0x7FFF);
			case .Int32: return (val >= -0x80000000) && (val <= 0x7FFF'FFFF);
			case .Int64: return (val >= -0x80000000'00000000) && (val <= 0x7FFFFFFF'FFFFFFFF);
			case .UInt8, .Char8: return (val >= 0) && (val <= 0xFF);
			case .UInt16, .Char16: return (val >= 0) && (val <= 0xFFFF);
			case .UInt32, .Char32: return (val >= 0) && (val <= 0xFFFFFFFF);
			case .UInt64: return (val >= 0) && (val <= 0x7FFFFFFF'FFFFFFFF);
#if BF_64_BIT
			case .Int: return (val >= -0x80000000'00000000) && (val <= 0x7FFFFFFF'FFFFFFFF);
			case .UInt: return (val >= 0) && (val <= 0x7FFFFFFF'FFFFFFFF);
#else
			case .Int: return (val >= -0x80000000) && (val <= 0x7FFF'FFFF);
			case .UInt: return (val >= 0) && (val <= 0xFFFFFFFF);
#endif
			default: return false;
			}
		}

		public static Result<Variant> ConvertTo(Object obj, Type type)
		{
			if (obj.GetType() == type)
			{
				return Variant.Create(obj, false);
			}

			var (objType, dataPtr) = GetTypeAndPointer(obj);
			if (objType.IsPrimitive)
			{
				if (objType.IsInteger)
				{
					int64 intVal = ToInt64(obj);
					switch (type.mTypeCode)
					{
					case .Float:
						float val = (.)intVal;
						return Variant.Create(type, &val);
					case .Double:
						double val = (.)intVal;
						return Variant.Create(type, &val);
					default:
					}

					if (IntCanFit(intVal, type))
					{
						return Variant.Create(type, &intVal);
					}
				}
				else if (objType.IsFloatingPoint)
				{
					if ((type.mTypeCode == .Double) &&
						(objType.mTypeCode == .Float))
					{
						double val = (.)*(float*)dataPtr;
						return Variant.Create(type, &val);
					}
				}
			}

			return .Err;
		}
	}
}