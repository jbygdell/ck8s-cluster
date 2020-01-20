import influxdb_size_based_metrics_retention as rentention
import unittest
import unittest.mock as mock
import os
import requests
import json


class TestGetConfig(unittest.TestCase):

    env_var_all_set = {
        'INFLUXDB_HOST': 'INFLUXDB_HOST_TEST_VALUE',
        'INFLUXDB_PORT': 'INFLUXDB_PORT_TEST_VALUE',
        'INFLUXDB_USER': 'INFLUXDB_USER_TEST_VALUE',
        'INFLUXDB_PASSWORD': 'INFLUXDB_PASSWORD_TEST_VALUE',
        'INFLUXDB_DATABASE': 'INFLUXDB_DATABASE_TEST_VALUE',
        'INFLUXDB_DATABASE_SIZE_LIMIT': 'INFLUXDB_DATABASE_SIZE_LIMIT_TEST_VALUE',
        'INFLUXDB_MIN_SHARDS': 'INFLUXDB_MIN_SHARDS_TEST_VALUE',
        'PROMETHEUS_HOST': 'PROMETHEUS_HOST_TEST_VALUE',
        'PROMETHEUS_PORT': 'PROMETHEUS_PORT_TEST_VALUE',
        'PROMETHEUS_INFLUXDB_METRIC': 'PROMETHEUS_INFLUXDB_METRIC_TEST_VALUE',
    }

    # env_var_all_correct = {
    #     'INFLUXDB_HOST': 'INFLUXDB_HOST_TEST_VALUE',
    #     'INFLUXDB_PORT': 'INFLUXDB_PORT_TEST_VALUE',
    #     'INFLUXDB_USER': 'INFLUXDB_USER_TEST_VALUE',
    #     'INFLUXDB_PASSWORD': 'INFLUXDB_PASSWORD_TEST_VALUE',
    #     'INFLUXDB_DATABASE': 'INFLUXDB_DATABASE_TEST_VALUE',
    #     'INFLUXDB_DATABASE_SIZE_LIMIT': '1000',
    #     'INFLUXDB_MIN_SHARDS': '1',
    #     'PROMETHEUS_HOST': 'PROMETHEUS_HOST_TEST_VALUE',
    #     'PROMETHEUS_PORT': 'PROMETHEUS_PORT_TEST_VALUE',
    #     'PROMETHEUS_INFLUXDB_METRIC': 'PROMETHEUS_INFLUXDB_METRIC_TEST_VALUE',
    # }

    env_var_set_except_prometheus_port = {
        'INFLUXDB_HOST': 'INFLUXDB_HOST_TEST_VALUE',
        'INFLUXDB_PORT': 'INFLUXDB_PORT_TEST_VALUE',
        'INFLUXDB_USER': 'INFLUXDB_USER_TEST_VALUE',
        'INFLUXDB_PASSWORD': 'INFLUXDB_PASSWORD_TEST_VALUE',
        'INFLUXDB_DATABASE': 'INFLUXDB_DATABASE_TEST_VALUE',
        'INFLUXDB_DATABASE_SIZE_LIMIT': 'INFLUXDB_DATABASE_SIZE_LIMIT_TEST_VALUE',
        'INFLUXDB_MIN_SHARDS': 'INFLUXDB_MIN_SHARDS_TEST_VALUE',
        'PROMETHEUS_HOST': 'PROMETHEUS_HOST_TEST_VALUE',
        # 'PROMETHEUS_PORT': 'PROMETHEUS_PORT_TEST_VALUE',
        'PROMETHEUS_INFLUXDB_METRIC': 'PROMETHEUS_INFLUXDB_METRIC_TEST_VALUE',
    }

    env_var_empty = {}

    def setUp(self):
        rentention.create_logger()

    @mock.patch.dict(os.environ, env_var_empty)
    def test_env_var_not_set(self):
        with self.assertRaisesRegex(KeyError, "INFLUXDB_HOST"):
            rentention.get_config()

    @mock.patch.dict(os.environ, env_var_set_except_prometheus_port)
    def test_env_var_subset_set(self):
        with self.assertRaisesRegex(KeyError, "PROMETHEUS_PORT"):
            rentention.get_config()

    @mock.patch.dict(os.environ, env_var_all_set)
    def test_all_env_var_set(self):
        rentention.get_config()
        self.assertEqual(rentention.INFLUXDB_HOST, 'INFLUXDB_HOST_TEST_VALUE')
        self.assertEqual(rentention.INFLUXDB_PORT, 'INFLUXDB_PORT_TEST_VALUE')

    @mock.patch.dict(os.environ, env_var_all_set)
    def test_parsing_failure(self):
        rentention.get_config()

        with self.assertRaisesRegex(ValueError, "INFLUXDB_DATABASE_SIZE_LIMIT_TEST_VALUE"):
            rentention.parse_numeric_config()

    # @mock.patch.dict(os.environ, env_var_all_correct)
    @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_DATABASE_SIZE_LIMIT_STRING', "1000")
    @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_MIN_SHARDS_STRING', "1")
    def test_parsing_successful(self):
        # rentention.get_config()
        rentention.parse_numeric_config()
        self.assertEqual(rentention.INFLUXDB_DATABASE_SIZE_LIMIT, 1000)
        self.assertEqual(rentention.INFLUXDB_MIN_SHARDS, 1)

    # FROM: https://gist.github.com/evansde77/45467f5a7af84d2a2d34f3fcb357449c#file-mock_requests-py-L13
    def _mock_response(
            self,
            status=200,
            content="CONTENT",
            json_data=None,
            raise_for_status=None):
        """
        since we typically test a bunch of different
        requests calls for a service, we are going to do
        a lot of mock responses, so its usually a good idea
        to have a helper function that builds these things
        """
        mock_resp = mock.Mock()
        # mock raise_for_status call w/optional error
        mock_resp.raise_for_status = mock.Mock()
        if raise_for_status:
            mock_resp.raise_for_status.side_effect = raise_for_status
        # set status code and content
        mock_resp.status_code = status
        mock_resp.content = content
        # add json data if provided
        if json_data:
            mock_resp.json = mock.Mock(
                return_value=json_data
            )
        return mock_resp    

    @mock.patch('requests.get')
    def test_get_db_size_connection_error(self, mock_get):
        mock_resp = self._mock_response(raise_for_status=ConnectionError)
        mock_get.return_value = mock_resp

        with self.assertRaises(ConnectionError):
            rentention.get_db_size()

    @mock.patch('requests.get')
    @mock.patch('influxdb_size_based_metrics_retention.PROMETHEUS_INFLUXDB_METRIC', "influxdb_service_cluster_size")
    def test_get_db_size_value_error(self, mock_get):
        bad_prometheus_json = {"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"influxdb_WORKLOAD_cluster_size","endpoint":"web","instance":"10.42.1.25:9100","job":"influxdb-du-monitoring-service","namespace":"influxdb-prometheus","pod":"influxdb-du-monitoring-deployment-75bf9fc77d-97k9c","service":"influxdb-du-monitoring-service"},"value":[1579515978.76,1157844]}]}}
        mock_resp = self._mock_response(json_data=bad_prometheus_json)
        mock_get.return_value = mock_resp

        with self.assertRaises(ValueError):
            rentention.get_db_size()

    @mock.patch('requests.get')
    @mock.patch('influxdb_size_based_metrics_retention.PROMETHEUS_INFLUXDB_METRIC', "influxdb_service_cluster_size")
    def test_get_db_size_successful(self, mock_get):
        expected_db_size = 1157844
        prometheus_json = {"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"influxdb_service_cluster_size","endpoint":"web","instance":"10.42.1.25:9100","job":"influxdb-du-monitoring-service","namespace":"influxdb-prometheus","pod":"influxdb-du-monitoring-deployment-75bf9fc77d-97k9c","service":"influxdb-du-monitoring-service"},"value":[1579515978.76,expected_db_size]}]}}
        mock_resp = self._mock_response(json_data=prometheus_json)
        mock_get.return_value = mock_resp

        actual_db_size = rentention.get_db_size()

        self.assertEqual(actual_db_size, expected_db_size)

    # @mock.patch('requests.get')
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_DATABASE_SIZE_LIMIT_STRING', "1000")
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_MIN_SHARDS_STRING', "5")
    # # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_MIN_SHARDS', 1)
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_DATABASE', "service_cluster")
    
    # def test_get_oldest_shard_not_enough_shards_error(self, mock_get):
    #     rentention.parse_numeric_config()

    #     influxdb_json = {"results":[{"statement_id":0,"series":[{"name":"service_cluster","columns":["id","database","retention_policy","shard_group","start_time","end_time","expiry_time","owners"],"values":[[7,"service_cluster","service_cluster_rp",7,"2020-01-17T00:00:00Z","2020-01-18T00:00:00Z","2020-01-21T00:00:00Z",""],[10,"service_cluster","service_cluster_rp",10,"2020-01-18T00:00:00Z","2020-01-19T00:00:00Z","2020-01-22T00:00:00Z",""],[13,"service_cluster","service_cluster_rp",13,"2020-01-19T00:00:00Z","2020-01-20T00:00:00Z","2020-01-23T00:00:00Z",""],[16,"service_cluster","service_cluster_rp",16,"2020-01-20T00:00:00Z","2020-01-21T00:00:00Z","2020-01-24T00:00:00Z",""]]},{"name":"workload_cluster","columns":["id","database","retention_policy","shard_group","start_time","end_time","expiry_time","owners"],"values":[[3,"workload_cluster","workload_cluster_rp",3,"2020-01-15T00:00:00Z","2020-01-16T00:00:00Z","2020-01-23T00:00:00Z",""],[5,"workload_cluster","workload_cluster_rp",5,"2020-01-16T00:00:00Z","2020-01-17T00:00:00Z","2020-01-24T00:00:00Z",""],[8,"workload_cluster","workload_cluster_rp",8,"2020-01-17T00:00:00Z","2020-01-18T00:00:00Z","2020-01-25T00:00:00Z",""],[11,"workload_cluster","workload_cluster_rp",11,"2020-01-18T00:00:00Z","2020-01-19T00:00:00Z","2020-01-26T00:00:00Z",""],[14,"workload_cluster","workload_cluster_rp",14,"2020-01-19T00:00:00Z","2020-01-20T00:00:00Z","2020-01-27T00:00:00Z",""],[17,"workload_cluster","workload_cluster_rp",17,"2020-01-20T00:00:00Z","2020-01-21T00:00:00Z","2020-01-28T00:00:00Z",""]]},{"name":"_internal","columns":["id","database","retention_policy","shard_group","start_time","end_time","expiry_time","owners"],"values":[[1,"_internal","monitor",1,"2020-01-15T00:00:00Z","2020-01-16T00:00:00Z","2020-01-23T00:00:00Z",""],[6,"_internal","monitor",6,"2020-01-16T00:00:00Z","2020-01-17T00:00:00Z","2020-01-24T00:00:00Z",""],[9,"_internal","monitor",9,"2020-01-17T00:00:00Z","2020-01-18T00:00:00Z","2020-01-25T00:00:00Z",""],[12,"_internal","monitor",12,"2020-01-18T00:00:00Z","2020-01-19T00:00:00Z","2020-01-26T00:00:00Z",""],[15,"_internal","monitor",15,"2020-01-19T00:00:00Z","2020-01-20T00:00:00Z","2020-01-27T00:00:00Z",""],[18,"_internal","monitor",18,"2020-01-20T00:00:00Z","2020-01-21T00:00:00Z","2020-01-28T00:00:00Z",""]]}]}]}
    #     mock_resp = self._mock_response(json_data=influxdb_json)
    #     mock_get.return_value = mock_resp

    #     with self.assertRaises(SystemExit):
    #         rentention.get_oldest_shard()

    @mock.patch('requests.get')
    @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_DATABASE_SIZE_LIMIT_STRING', "1000")
    @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_MIN_SHARDS_STRING', "1")
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_MIN_SHARDS', 1)
    @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_DATABASE', "service_cluster")
    
    def test_get_oldest_shard_successful(self, mock_get):
        expected_oldest_shard_id = 7
        rentention.parse_numeric_config()

        influxdb_json = {"results":[{"statement_id":0,"series":[{"name":"service_cluster","columns":["id","database","retention_policy","shard_group","start_time","end_time","expiry_time","owners"],"values":[[7,"service_cluster","service_cluster_rp",7,"2020-01-17T00:00:00Z","2020-01-18T00:00:00Z","2020-01-21T00:00:00Z",""],[10,"service_cluster","service_cluster_rp",10,"2020-01-18T00:00:00Z","2020-01-19T00:00:00Z","2020-01-22T00:00:00Z",""],[13,"service_cluster","service_cluster_rp",13,"2020-01-19T00:00:00Z","2020-01-20T00:00:00Z","2020-01-23T00:00:00Z",""],[16,"service_cluster","service_cluster_rp",16,"2020-01-20T00:00:00Z","2020-01-21T00:00:00Z","2020-01-24T00:00:00Z",""]]},{"name":"workload_cluster","columns":["id","database","retention_policy","shard_group","start_time","end_time","expiry_time","owners"],"values":[[3,"workload_cluster","workload_cluster_rp",3,"2020-01-15T00:00:00Z","2020-01-16T00:00:00Z","2020-01-23T00:00:00Z",""],[5,"workload_cluster","workload_cluster_rp",5,"2020-01-16T00:00:00Z","2020-01-17T00:00:00Z","2020-01-24T00:00:00Z",""],[8,"workload_cluster","workload_cluster_rp",8,"2020-01-17T00:00:00Z","2020-01-18T00:00:00Z","2020-01-25T00:00:00Z",""],[11,"workload_cluster","workload_cluster_rp",11,"2020-01-18T00:00:00Z","2020-01-19T00:00:00Z","2020-01-26T00:00:00Z",""],[14,"workload_cluster","workload_cluster_rp",14,"2020-01-19T00:00:00Z","2020-01-20T00:00:00Z","2020-01-27T00:00:00Z",""],[17,"workload_cluster","workload_cluster_rp",17,"2020-01-20T00:00:00Z","2020-01-21T00:00:00Z","2020-01-28T00:00:00Z",""]]},{"name":"_internal","columns":["id","database","retention_policy","shard_group","start_time","end_time","expiry_time","owners"],"values":[[1,"_internal","monitor",1,"2020-01-15T00:00:00Z","2020-01-16T00:00:00Z","2020-01-23T00:00:00Z",""],[6,"_internal","monitor",6,"2020-01-16T00:00:00Z","2020-01-17T00:00:00Z","2020-01-24T00:00:00Z",""],[9,"_internal","monitor",9,"2020-01-17T00:00:00Z","2020-01-18T00:00:00Z","2020-01-25T00:00:00Z",""],[12,"_internal","monitor",12,"2020-01-18T00:00:00Z","2020-01-19T00:00:00Z","2020-01-26T00:00:00Z",""],[15,"_internal","monitor",15,"2020-01-19T00:00:00Z","2020-01-20T00:00:00Z","2020-01-27T00:00:00Z",""],[18,"_internal","monitor",18,"2020-01-20T00:00:00Z","2020-01-21T00:00:00Z","2020-01-28T00:00:00Z",""]]}]}]}
        mock_resp = self._mock_response(json_data=influxdb_json)
        mock_get.return_value = mock_resp

        actual_oldest_shard_id = rentention.get_oldest_shard()
        self.assertEqual(actual_oldest_shard_id, expected_oldest_shard_id)

    @mock.patch('requests.post')
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_DATABASE_SIZE_LIMIT_STRING', "1000")
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_MIN_SHARDS_STRING', "1")
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_MIN_SHARDS', 1)
    # @mock.patch('influxdb_size_based_metrics_retention.INFLUXDB_DATABASE', "service_cluster")
    def test_drop_shard_successful(self, mock_get):
        mock_resp = self._mock_response()
        mock_get.return_value = mock_resp

        shard_id = 1

        rentention.drop_shard(shard_id)

    # @mock.patch('influxdb_size_based_metrics_retention.create_logger', return_value=None)
    def test_main_successful(self):
        # with mock.patch.object(rentention, 'create_logger', autospec=True) as mock_foo:
            # mock_foo.create_logger = None
        rentention.main()

# if __name__ == '__main__':
#     unittest.main()
