<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ProjectEdit" CodeBehind="ProjectEdit.aspx.vb" %>

<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<%@ Register TagPrefix="uc" TagName="SecurityGroups" Src="Controls\SecurityGroups.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False"></Controls:DeleteButton>
            <span class="tooldiv" id="ImportDiv" runat="server"></span>
            <asp:Button ID="btnImport" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Import %>" ToolTip="<%$Resources:Strings, ImportHelp %>" />
            <asp:Button ID="btnExport" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Export %>" />
            <asp:Button ID="btnPublish" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Publish %>" ToolTip="<%$Resources:Strings, PublishProjectHelp %>" />
            <input type="button" id="btnWebDesign" runat="server" class="toolbtn" visible="false" value="<%$Resources:Strings, Design %>" title="<%$Resources:Strings, DesignProjectHelp %>"
                onclick="window.open('WebDesign/editor.html?v=106882799234227327#/?id=" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnVersions" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, VersionHistory %>" ToolTip="<%$Resources:Strings, VersionsHelp %>" />
            <asp:Button ID="btnProjects" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Projects %>" ToolTip="<%$Resources:Strings, FragmentProjectsHelp %>" />
            <asp:Button ID="btnFolders" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, PublishFolders %>" ToolTip="<%$Resources:Strings, FoldersHelp %>" />
            <asp:Button ID="btnResponses" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Report_Response %>" ToolTip="<%$Resources:Strings, ResponsesHelp %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="lblProjectName" runat="server" Text="<%$Resources:Strings, Name %>" AssociatedControlID="lblName"></asp:Label></td>
                    <td>
                        <asp:Label ID="lblName" runat="server" CssClass="fld"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblProjectType" runat="server" Text="<%$Resources:Strings, Type %>"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="txtProjectType" runat="server" CssClass="fld"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblProjectID" runat="server" Text="<%$Resources:Strings, ID %>"></asp:Label></td>
                    <td>
                        <asp:Label ID="lblProjectGUID" runat="server" Text="" CssClass="fld"></asp:Label></td>
                </tr>
                <tr id="trLockedBy" runat="server">
                    <td>
                        <asp:Label ID="lblProjectLockedBy" runat="server" Text="<%$Resources:Strings, LockedBy %>"></asp:Label></td>
                    <td>
                        <asp:Label ID="txtProjectLockedBy" runat="server" Text="" CssClass="fld"></asp:Label>
                        <span class="tooldiv" id="UnlockDiv" runat="server"></span>
                        <asp:LinkButton ID="lnkUnlock" runat="server" Style="color: red; font-weight: bold;" Text="<%$Resources:Strings, ForceUnlock %>" />
                        <asp:HiddenField ID="hfComment" runat="server" />
                    </td>
                </tr>
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblFolder" runat="server" Text="<%$Resources:Strings, Folder %>"
                            AssociatedControlID="lstFolder"></asp:Label>
                    </td>
                    <td>
                        <asp:DropDownList ID="lstFolder" runat="server" CssClass="fld">
                        </asp:DropDownList>
                    </td>
                </tr>
            </table>
            <br />
        </div>
    </div>
</asp:Content>

