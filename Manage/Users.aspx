<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Users" Codebehind="Users.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnNew" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewUser %>">
            </asp:Button>
            <span class="tooldiv" id="ExportDiv" runat="server"></span>
            <asp:Button ID="btnExport" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Export %>">
            </asp:Button>
            <asp:Button ID="btnSync" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Sync %>">
            </asp:Button>
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="searcharea">
                    <table role="presentation">
                        <tr>
                            <td>
                                <asp:Label ID="litUserName" runat="server" Text="" AssociatedControlID="txtUserName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtUserName" runat="server"></asp:TextBox>
                            </td>
                            <td>
                                <asp:Label ID="litPleaseEnter" runat="server" Text="<%$Resources:Strings, Group %>" AssociatedControlID="lstUserGroup"></asp:Label>
                            </td>
                            <td >
                                <asp:DropDownList ID="lstUserGroup" runat="server">
                                </asp:DropDownList></td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="litFirstName" runat="server" Text="<%$Resources:Strings, FirstName %>" AssociatedControlID="txtFirstName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtFirstName" runat="server"></asp:TextBox>
                            </td>
                            <td>
                                <asp:Label ID="lblShowActive" runat="server" Text="<%$Resources:Strings, Show %>" AssociatedControlID="lstShowActive"></asp:Label>
                            </td>
                            <td>
                                <asp:DropDownList ID="lstShowActive" runat="server">
                                </asp:DropDownList>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="litLastName" runat="server" Text="<%$Resources:Strings, LastName %>" AssociatedControlID="txtLastName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtLastName" runat="server"></asp:TextBox>
                            </td>
                            <td>
                                <asp:Button ID="btnSearch" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Search %>" />
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="body">
                    <Controls:PagedGridView ID="grdUsers" runat="server" Width="100%" AutoGenerateColumns="False"
                        EnableViewState="False" DataSourceID="odsUsers" PageSize="50" CssClass="grd">
                        <Columns>
                            <asp:TemplateField HeaderText="">
                                <ItemTemplate>
                                    <a href="UserEdit.aspx?id=<%#Eval("UserId") %>&userguid=<%#Eval("UserGuid") %>"><%#DisplayUserName(Container.DataItem)%></a>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="">
                                <ItemTemplate>
                                    <asp:Literal runat="server" Text="<%#DisplayFirstName(Container.DataItem)%>"></asp:Literal>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:BoundField DataField="AddressDetails.LastName" HeaderText="<%$Resources:Strings, LastName %>" />
                            <asp:TemplateField HeaderText="Roles">
                                <ItemTemplate>
                                    <asp:Literal runat="server" Text="<%#DisplayRoles(Container.DataItem) %>"></asp:Literal>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate><asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoUsers %>" /></EmptyDataTemplate>
                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsUsers" runat="server" SelectMethod="GetUsers" SelectCountMethod="GetUsersCount" TypeName="Intelledox.Controller.UserController" EnablePaging="true">
                        <SelectParameters>
                            <asp:Parameter Name="businessUnitGuid" Type="Object" />
                            <asp:ControlParameter ControlID="lstUserGroup" PropertyName="SelectedValue" Name="searchGroup" Type="Object" />
                            <asp:ControlParameter ControlID="txtUserName" PropertyName="Text" Name="searchUserName" Type="String" ConvertEmptyStringToNull="false" />
                            <asp:ControlParameter ControlID="txtFirstName" PropertyName="Text" Name="searchFirstName" Type="String" ConvertEmptyStringToNull="false" />
                            <asp:ControlParameter ControlID="txtLastName" PropertyName="Text" Name="searchLastName" Type="String" ConvertEmptyStringToNull="false" />
                            <asp:ControlParameter ControlID="lstShowActive" PropertyName="SelectedValue" Name="showActive" Type="Object" />
                            <asp:Parameter Name="startRowIndex" Type="Int32" />
                            <asp:Parameter Name="maximumRows" Type="Int32" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
