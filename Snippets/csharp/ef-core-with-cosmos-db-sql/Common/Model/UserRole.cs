using Microsoft.EntityFrameworkCore;

namespace Common.Model
{
    [Owned]
    public class UserRole
    {
        public string OrganisationId { get; set; }

        public string RoleName { get; set; }
    }
}
