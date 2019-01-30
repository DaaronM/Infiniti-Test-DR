<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.TaskHistory" Codebehind="TaskHistory.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="toolbar">
                    <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" text="<%$Resources:Strings, Back %>" />
                </div>
                <div class="body">
                    <div>
                        <asp:Label ID="lblProjectName" runat="server" Text="<%$Resources:Strings, Project %>"></asp:Label>:&nbsp;
                        <asp:Label ID="txtProjectName" runat="server"></asp:Label>
                    </div>
                    <br />
                    <asp:GridView ID="grdTaskHistory" runat="server" Width="100%" AutoGenerateColumns="False" CssClass="grd" BorderWidth="0">
                        <Columns>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("StateName"))%> 
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("CreatedDateUTC"), DateTime), "g")%>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# Microsoft.Security.Application.Encoder.HtmlEncode(AssignedToDisplayName(Eval("AssignedType"), Eval("AssignedToUserName"), Eval("AssignedToName"), Eval("AssignedToGroupName"), Eval("LockedByUserName"), Eval("LockedByName")))%> 
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# If(Eval("IsComplete") = True,
                                                     Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("CompletedDateUTC"), DateTime), "g"),
                                                     Resources.Strings.None)%>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate><asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoHistory %>" /></EmptyDataTemplate>
                    </asp:GridView>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
 </asp:Content>

