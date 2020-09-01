using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.Azure.Cosmos.Table;
using Common.Model;

namespace Common
{
    public class EntityManager<T> where T : EntityBase, new()
    {

        private readonly CloudTable _table;

        public EntityManager(CloudTable table)
        {
            _table = table ?? throw new ArgumentNullException(nameof(table));
        }

        public IQueryable<T> GetQuery()
        {
            try
            {
                return _table.CreateQuery<T>().OrderByDesc(nameof(TableEntity.RowKey));
            }
            catch (StorageException)
            {
                throw;
            }
        }

        public Task<IList<T>> GetWhereAsync(Func<T, bool> predicate)
        {
            try
            {
                IList<T> result = _table.CreateQuery<T>().Where(predicate).ToArray();

                return Task.FromResult(result);
            }
            catch (StorageException)
            {
                throw;
            }
        }

        public async Task<T> GetAsync(string partitionKey, string rowKey)
        {
            try
            {
                TableOperation retrieveOperation = TableOperation.Retrieve<T>(partitionKey, rowKey);
                TableResult result = await _table.ExecuteAsync(retrieveOperation);

                return result.Result as T;
            }
            catch (StorageException)
            {
                throw;
            }
        }

        public Task<T> GetAsync(string entityKey)
        {
            var (partitionKey, rowKey) = EntityBase.ParseKeys(entityKey);

            return GetAsync(partitionKey, rowKey);
        }

        public async Task<T> CreateOrUpdate(T entity)
        {
            try
            {
                TableOperation insertOrMergeOperation = TableOperation.InsertOrReplace(entity);
                TableResult result = await _table.ExecuteAsync(insertOrMergeOperation);

                return result.Result as T;
            }
            catch (StorageException)
            {
                throw;
            }
        }

        /// <summary>
        /// Note: This method fails when change-set is bigger than 100 entries (maximal batch size)
        /// </summary>
        public async Task<int> Synchronize(Func<T, bool> predicate, ICollection<T> entities)
        {
            try
            {
                var existingKeys = _table.CreateQuery<T>().Where(predicate).Select(x => new { x.PartitionKey, x.RowKey }).ToArray();

                var created = 0;
                var updated = 0;
                var deleted = 0;

                var batchOperation = new TableBatchOperation();

                foreach (var entity in entities.Where(e => !existingKeys.Any(x => x.PartitionKey == e.PartitionKey && x.RowKey == e.RowKey)))
                {
                    batchOperation.Add(TableOperation.InsertOrReplace(entity));
                    created++;
                }

                foreach (var entity in entities.Where(e => existingKeys.Any(x => x.PartitionKey == e.PartitionKey && x.RowKey == e.RowKey)))
                {
                    batchOperation.Add(TableOperation.InsertOrReplace(entity));
                    updated++;
                }

                foreach (var keyPair in existingKeys.Where(x => !entities.Any(e => x.PartitionKey == e.PartitionKey && x.RowKey == e.RowKey)))
                {
                    var entity = await GetAsync(keyPair.PartitionKey, keyPair.RowKey);

                    batchOperation.Add(TableOperation.Delete(entity));
                    deleted++;
                }

                TableBatchResult result = null;
                if (batchOperation.Count > 0)
                    result = await _table.ExecuteBatchAsync(batchOperation);

                return created + updated + deleted;
            }
            catch (StorageException)
            {
                throw;
            }
        }

        public async Task<bool> Delete(string entityKey)
        {
            try
            {
                var entity = await GetAsync(entityKey);
                if (entity == null)
                    return false;

                TableOperation deleteOperation = TableOperation.Delete(entity);
                TableResult result = await _table.ExecuteAsync(deleteOperation);

                return true;
            }
            catch (StorageException)
            {
                throw;
            }
        }

        public async Task<int> DeleteWhere(Func<T, bool> predicate)
        {
            try
            {
                var entities = await GetWhereAsync(predicate);
                var count = 0;

                foreach (var entity in entities)
                {
                    TableOperation deleteOperation = TableOperation.Delete(entity);
                    TableResult result = await _table.ExecuteAsync(deleteOperation);

                    count++;
                }

                return count;
            }
            catch (StorageException)
            {
                throw;
            }
        }
    }

    public static class EntityManager
    {
        private static CloudTableClient tableClient;

        public static EntityManager<T> Get<T>(string storageConnectionString) where T : EntityBase, new()
        {
            if (tableClient == null)
            {
                tableClient = CloudStorageAccount.Parse(storageConnectionString).CreateCloudTableClient(new TableClientConfiguration());
            }

            var tableName = typeof(T).Name.ToLower();
            CloudTable table = tableClient.GetTableReference(tableName);
            if (table.CreateIfNotExists())
            {
            }

            return new EntityManager<T>(table);
        }
    }
}
