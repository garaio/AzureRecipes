using Common.Definition;
using System.Collections.Generic;

namespace Common.Model
{
    public class User : EntityBase
    {
        public string IdentityId { get => PartitionKey; set => PartitionKey = value; }

        public string DisplayName { get; set; }

        public Language Language { get; set; }

        public bool IsActive { get; set; }

        public IList<UserRole> Roles { get; set; } = new List<UserRole>();
    }
}
