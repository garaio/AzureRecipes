using Microsoft.EntityFrameworkCore;

namespace Common.Model
{
    public class DemoDbContext : DbContext
    {
        public DemoDbContext(DbContextOptions options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }

        public DbSet<Organisation> Organisations { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>()
                .ToContainer("Users")
                .HasNoDiscriminator()
                .HasPartitionKey(o => o.PartitionKey);

            modelBuilder.Entity<Organisation>()
                .ToContainer("Organisations")
                .HasNoDiscriminator()
                .HasPartitionKey(o => o.PartitionKey);

            base.OnModelCreating(modelBuilder);
        }
    }
}
