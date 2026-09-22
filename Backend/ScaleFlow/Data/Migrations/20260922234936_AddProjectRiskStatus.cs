using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ScaleFlow.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddProjectRiskStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsAtRisk",
                table: "Projects",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsAtRisk",
                table: "Projects");
        }
    }
}
