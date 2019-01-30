<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.FragmentProjects" Codebehind="FragmentProjects.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>">
            </asp:Button>
        </div>
        <asp:UpdatePanel ID="projectsPanel" runat="server">
            <ContentTemplate>
                <div class="body">
                    <Controls:PagedGridView ID="grdProjects" runat="server" Width="100%" AutoGenerateColumns="False"
                        EnableViewState="False" DataSourceID="odsProjects" PageSize="50" CssClass="grd">
                        <Columns>
                            <asp:BoundField DataField="Name" HeaderText="<%$Resources:Strings, ProjectName %>" />
                            <asp:BoundField DataField="ProjectTypeId" HeaderText="<%$Resources:Strings, Type %>" />                         
                        </Columns>
                        <EmptyDataTemplate><asp:Literal ID="msgNoProjects" runat="server" Text="<%$Resources:Strings, NoFragmentProjects %>" /></EmptyDataTemplate>
                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsProjects" runat="server" SelectMethod="GetProjectsUsingFragment" TypeName="Intelledox.Controller.ProjectController">
                        <SelectParameters>
                            <asp:Parameter Name="ProjectGuid" Type="Object" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
