using ContosoUniversity.Models;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace ContosoUniversity.Tests
{
    [TestClass]
    public class DepartmentTest
    {
        [TestMethod]
        public void TestMethod1()
        {
            var department = new Department
            {
                Name = "dep1",
                DepartmentID = 1
            };
            Assert.AreEqual(0, department.DepartmentID);            
        }
    }
}
