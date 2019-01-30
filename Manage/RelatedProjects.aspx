<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.RelatedProjects" Codebehind="RelatedProjects.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>">
            </asp:Button>
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="body">
                    <Controls:PagedGridView ID="grdProjects" runat="server" Width="100%" AutoGenerateColumns="False"
                        EnableViewState="False" DataSourceID="odsProjects" PageSize="50" CssClass="grd">
                        <Columns>
                            <asp:BoundField DataField="Name" />
                            <asp:BoundField DataField="ProjectTypeId" />
                            <asp:BoundField DataField="ModifiedDateUtc" />
                            <asp:BoundField DataField="ModifiedBy" />
                        </Columns>
                        <EmptyDataTemplate><asp:Literal runat="server" Text="<%$Resources:Strings, NoRelatedProjects %>" /></EmptyDataTemplate>

                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsProjects" runat="server" SelectMethod="GetProjectsByContentItem" TypeName="Intelledox.Controller.ProjectController">
                        <SelectParameters>
                            <asp:Parameter Name="ContentGuid" Type="Object" />
                            <asp:Parameter Name="BusinessUnitGuid" Type="Object" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
