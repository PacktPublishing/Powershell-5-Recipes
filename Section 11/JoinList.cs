using System.Management.Automation;
using System.Linq;

namespace MyModule
{
	[Cmdlet(VerbsCommon.Join, "List")]
 	public class JoinListCommand : Cmdlet
	{
	 	[Parameter(Mandatory = true, Position = 0)]
  		public ScriptBlock Block {get; set;}

		[Parameter(Mandatory = true, ValueFromPipeline = true)]
		public object Item{get; set;}

		[Parameter(Mandatory = false)]
  		public object Initial{get; set;}

  		private object aggregate;

  		protected override void BeginProcessing()
  		{
  			base.BeginProcessing();
  			if (Initial != null) aggregate = Initial;
  		}

  		protected override void ProcessRecord()
  		{
  			base.ProcessRecord();
  			aggregate = Block.Invoke(Item, aggregate).First();
  		}

  		protected override void EndProcessing() 
  		{
  			base.EndProcessing();
  			WriteObject(aggregate);
  		} 
  	}
}