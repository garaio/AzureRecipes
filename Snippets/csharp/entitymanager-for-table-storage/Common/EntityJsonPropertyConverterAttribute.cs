using System;

namespace Common
{
    [AttributeUsage(AttributeTargets.Property)]
    public class EntityJsonPropertyConverterAttribute : Attribute
    {
        public EntityJsonPropertyConverterAttribute()
        {
        }
    }
}
