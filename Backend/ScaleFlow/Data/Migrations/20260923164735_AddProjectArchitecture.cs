using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ScaleFlow.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddProjectArchitecture : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ProjectArchitectures",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ProjectId = table.Column<int>(type: "int", nullable: false),
                    Frontend = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Backend = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Database = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Authentication = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AiMl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    RealTime = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ExternalServices = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectArchitectures", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProjectArchitectures_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ProjectArchitectures_ProjectId",
                table: "ProjectArchitectures",
                column: "ProjectId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ProjectArchitectures");
        }
    }
}
