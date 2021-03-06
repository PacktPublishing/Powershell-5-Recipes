using RestSharp;
using RestSharp.Deserializers;
using System;
using System.Collections.Generic;

namespace DnsimpleV2qq
{
	public class DnsimpleClient
	{
		private readonly string _accessToken;
		private readonly string _account;
		public DnsimpleClient(string account, string accessToken)
		{
			_accessToken = accessToken;
			_account = account;
		}

		public ZoneRecords GetZoneRecords(string zone) 
		{
			var client = new RestClient("https://api.dnsimple.com/v2/");
			var request = new RestRequest("/{account}/zones/{zone}/records");
			request.AddUrlSegment("account", _account);
			request.AddUrlSegment("zone", zone);
			request.AddHeader("Authorization",
				string.Format("Bearer {0}", _accessToken));
			return client.Execute<ZoneRecords>(request).Data;
		}
	}

	public class ZoneRecords
	{
		public List<ZoneRecord> data {get; set;}
	}

	public class ZoneRecord
	{
  		[DeserializeAs(Name = "id")]
		public int Id { get; set; }
		[DeserializeAs(Name = "zone_id")]
		public string ZoneId { get; set;}
		[DeserializeAs(Name = "parent_id")]
		public string ParentId { get; set; }
		[DeserializeAs(Name = "name")]
		public string Name { get; set; }
		[DeserializeAs(Name = "content")]
		public string content { get; set; }
		[DeserializeAs(Name = "ttl")]
		public int Ttl { get; set; }
		[DeserializeAs(Name = "priority")]
		public int Priority { get; set; }
		[DeserializeAs(Name = "type")]
		public string Type { get; set; }
		[DeserializeAs(Name = "regions")]
		public List<string> Regions {get; set;}
		[DeserializeAs(Name = "system_record")]
		public bool IsSystemRecord { get; set;}
		[DeserializeAs(Name = "created_at")]
		public DateTimeOffset CreatedAt { get; set;}
		[DeserializeAs(Name = "updated_at")]
		public DateTimeOffset UpdatedAt { get ;set;}
	}
}